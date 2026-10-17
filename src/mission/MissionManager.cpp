#include "MissionManager.h"
#include "mavlink/MAVLinkManager.h"
#include "mavlink/MAVLinkSender.h"
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcMission, "igcs.mission")

namespace IndigenousGCS {

MissionManager::MissionManager(MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent)
    , m_mavlink(mavlink)
    , m_mission(std::make_unique<Mission>(this))
{
    m_timeoutTimer.setSingleShot(true);
    connect(&m_timeoutTimer, &QTimer::timeout, this, &MissionManager::onTimeout);
}

void MissionManager::uploadMission(uint8_t targetSys, uint8_t targetComp)
{
    if (transferInProgress()) {
        emit transferFailed("A mission transfer is already in progress");
        return;
    }
    const QStringList errors = m_mission->validate();
    if (!errors.isEmpty()) {
        setState(MissionTransferState::Failed);
        emit transferFailed("Validation: " + errors.join("; "));
        return;
    }
    if (targetSys == 0) {
        setState(MissionTransferState::Failed);
        emit transferFailed("No flight controller is connected");
        return;
    }
    m_targetSys  = targetSys;
    m_targetComp = targetComp;
    m_nextSeq    = 0;
    m_transferProgress = 0;
    emit transferProgressChanged();
    setState(MissionTransferState::Uploading);

    m_mavlink->sender()->sendMissionCount(targetSys, targetComp,
                                          static_cast<uint16_t>(m_mission->count()));
    m_timeoutTimer.start(kTimeoutMs);
    qCInfo(lcMission) << "Upload started, count=" << m_mission->count();
}

void MissionManager::downloadMission(uint8_t targetSys, uint8_t targetComp)
{
    if (transferInProgress()) {
        emit transferFailed("A mission transfer is already in progress");
        return;
    }
    if (targetSys == 0) {
        setState(MissionTransferState::Failed);
        emit transferFailed("No flight controller is connected");
        return;
    }
    m_targetSys    = targetSys;
    m_targetComp   = targetComp;
    m_downloadBuffer.clear();
    m_nextSeq      = 0;
    m_expectedCount = 0;
    m_transferProgress = 0;
    emit transferProgressChanged();
    setState(MissionTransferState::Downloading);

    m_mavlink->sender()->sendMissionRequestList(targetSys, targetComp);
    m_timeoutTimer.start(kTimeoutMs);
    qCInfo(lcMission) << "Download started";
}

void MissionManager::clearMission(uint8_t targetSys, uint8_t targetComp)
{
    if (transferInProgress()) {
        emit transferFailed("A mission transfer is already in progress");
        return;
    }
    if (targetSys == 0) {
        setState(MissionTransferState::Failed);
        emit transferFailed("No flight controller is connected");
        return;
    }
    m_targetSys = targetSys;
    m_targetComp = targetComp;
    m_transferProgress = 0;
    emit transferProgressChanged();
    setState(MissionTransferState::Clearing);
    m_mavlink->sender()->sendMissionClearAll(targetSys, targetComp);
    m_timeoutTimer.start(kTimeoutMs);
}

void MissionManager::handleMessage(const mavlink_message_t &msg)
{
    switch (msg.msgid) {
    case MAVLINK_MSG_ID_MISSION_REQUEST:     handleMissionRequest(msg);    break;
    case MAVLINK_MSG_ID_MISSION_REQUEST_INT: handleMissionRequestInt(msg); break;
    case MAVLINK_MSG_ID_MISSION_ACK:         handleMissionAck(msg);        break;
    case MAVLINK_MSG_ID_MISSION_COUNT:       handleMissionCount(msg);      break;
    case MAVLINK_MSG_ID_MISSION_ITEM_INT:    handleMissionItemInt(msg);    break;
    case MAVLINK_MSG_ID_MISSION_ITEM:       handleMissionItem(msg);       break;
    default: break;
    }
}

void MissionManager::handleMissionRequest(const mavlink_message_t &msg)
{
    mavlink_mission_request_t req;
    mavlink_msg_mission_request_decode(&msg, &req);
    if (m_transferState != MissionTransferState::Uploading || !isTargetMessage(msg)) return;
    m_nextSeq = req.seq;
    sendNextItem(false);
}

void MissionManager::handleMissionRequestInt(const mavlink_message_t &msg)
{
    mavlink_mission_request_int_t req;
    mavlink_msg_mission_request_int_decode(&msg, &req);
    if (m_transferState != MissionTransferState::Uploading || !isTargetMessage(msg)) return;
    m_nextSeq = req.seq;
    sendNextItem(true);
}

void MissionManager::sendNextItem(bool useIntProtocol)
{
    m_timeoutTimer.start(kTimeoutMs);
    const auto &wps = m_mission->waypoints();
    if (m_nextSeq >= static_cast<uint16_t>(wps.size())) {
        m_timeoutTimer.stop();
        setState(MissionTransferState::Failed);
        emit transferFailed(QString("Flight controller requested invalid waypoint %1").arg(m_nextSeq));
        return;
    }

    const Waypoint &waypoint = wps[m_nextSeq];
    if (useIntProtocol) {
        m_mavlink->sender()->sendMissionItemInt(
            m_targetSys, m_targetComp, waypoint.toMavlinkItem());
    } else {
        mavlink_mission_item_t item{};
        item.seq = waypoint.seq;
        item.command = waypoint.command;
        item.frame = waypoint.frame;
        item.current = waypoint.current ? 1 : 0;
        item.autocontinue = waypoint.autoContinue ? 1 : 0;
        item.param1 = waypoint.param1;
        item.param2 = waypoint.param2;
        item.param3 = waypoint.param3;
        item.param4 = waypoint.param4;
        item.x = static_cast<float>(waypoint.latitude);
        item.y = static_cast<float>(waypoint.longitude);
        item.z = waypoint.altitude;
        m_mavlink->sender()->sendMissionItem(m_targetSys, m_targetComp, item);
    }

    m_transferProgress = (m_nextSeq * 100) / qMax(1, wps.size());
    emit transferProgressChanged();
    qCDebug(lcMission) << "Sent item" << m_nextSeq;
}

void MissionManager::handleMissionAck(const mavlink_message_t &msg)
{
    if (!isTargetMessage(msg)) return;
    if (m_transferState != MissionTransferState::Uploading &&
        m_transferState != MissionTransferState::Clearing)
        return;

    mavlink_mission_ack_t ack;
    mavlink_msg_mission_ack_decode(&msg, &ack);
    m_timeoutTimer.stop();

    if (ack.type == MAV_MISSION_ACCEPTED) {
        const MissionTransferState completedOperation = m_transferState;
        setState(MissionTransferState::Complete);
        m_transferProgress = 100;
        emit transferProgressChanged();
        if (completedOperation == MissionTransferState::Uploading)
            emit uploadComplete();
        else if (completedOperation == MissionTransferState::Clearing) {
            m_mission->clear();
            emit clearComplete();
        }
        qCInfo(lcMission) << "Mission ACK accepted for operation"
                          << static_cast<int>(completedOperation);
    } else {
        setState(MissionTransferState::Failed);
        emit transferFailed(QString("Mission ACK error: %1").arg(ack.type));
        qCWarning(lcMission) << "Mission ACK error" << ack.type;
    }
}

void MissionManager::handleMissionCount(const mavlink_message_t &msg)
{
    if (m_transferState != MissionTransferState::Downloading || !isTargetMessage(msg)) return;
    mavlink_mission_count_t cnt;
    mavlink_msg_mission_count_decode(&msg, &cnt);
    if (cnt.mission_type != MAV_MISSION_TYPE_MISSION) return;
    if (cnt.count > 4096) {
        m_timeoutTimer.stop();
        setState(MissionTransferState::Failed);
        emit transferFailed(QString("Flight controller mission is too large (%1 items)").arg(cnt.count));
        return;
    }
    m_expectedCount = cnt.count;
    m_nextSeq = 0;
    m_downloadUsesInt = false;
    m_downloadBuffer.clear();

    if (m_expectedCount == 0) {
        m_timeoutTimer.stop();
        m_mission->clear();
        setState(MissionTransferState::Complete);
        m_transferProgress = 100;
        emit transferProgressChanged();
        emit downloadComplete();
        return;
    }
    m_mavlink->sender()->sendMissionRequest(m_targetSys, m_targetComp, 0);
    m_timeoutTimer.start(kTimeoutMs);
}

void MissionManager::handleMissionItemInt(const mavlink_message_t &msg)
{
    if (m_transferState != MissionTransferState::Downloading || !isTargetMessage(msg)) return;
    mavlink_mission_item_int_t item;
    mavlink_msg_mission_item_int_decode(&msg, &item);

    if (item.mission_type != MAV_MISSION_TYPE_MISSION || item.seq != m_nextSeq) {
        m_downloadUsesInt = true;
        m_mavlink->sender()->sendMissionRequestInt(m_targetSys, m_targetComp, m_nextSeq);
        m_timeoutTimer.start(kTimeoutMs);
        return;
    }
    m_downloadUsesInt = true;
    appendDownloadedWaypoint(Waypoint::fromMavlinkItem(item));
}

void MissionManager::handleMissionItem(const mavlink_message_t &msg)
{
    if (m_transferState != MissionTransferState::Downloading || !isTargetMessage(msg)) return;
    mavlink_mission_item_t item;
    mavlink_msg_mission_item_decode(&msg, &item);
    if (item.mission_type != MAV_MISSION_TYPE_MISSION) return;
    if (item.seq != m_nextSeq) {
        m_downloadUsesInt = false;
        m_mavlink->sender()->sendMissionRequest(m_targetSys, m_targetComp, m_nextSeq);
        m_timeoutTimer.start(kTimeoutMs);
        return;
    }
    m_downloadUsesInt = false;
    mavlink_mission_item_int_t itemInt{};
    itemInt.seq = item.seq;
    itemInt.command = item.command;
    itemInt.frame = item.frame;
    itemInt.current = item.current;
    itemInt.autocontinue = item.autocontinue;
    itemInt.param1 = item.param1;
    itemInt.param2 = item.param2;
    itemInt.param3 = item.param3;
    itemInt.param4 = item.param4;
    itemInt.x = static_cast<int32_t>(item.x * 1e7);
    itemInt.y = static_cast<int32_t>(item.y * 1e7);
    itemInt.z = item.z;
    itemInt.mission_type = MAV_MISSION_TYPE_MISSION;
    appendDownloadedWaypoint(Waypoint::fromMavlinkItem(itemInt));
}

void MissionManager::appendDownloadedWaypoint(const Waypoint &waypoint)
{
    m_downloadBuffer.append(waypoint);
    ++m_nextSeq;
    m_transferProgress = (m_downloadBuffer.size() * 100) / qMax(1, (int)m_expectedCount);
    emit transferProgressChanged();

    if (static_cast<uint16_t>(m_downloadBuffer.size()) < m_expectedCount) {
        if (m_downloadUsesInt)
            m_mavlink->sender()->sendMissionRequestInt(m_targetSys, m_targetComp, m_nextSeq);
        else
            m_mavlink->sender()->sendMissionRequest(m_targetSys, m_targetComp, m_nextSeq);
        m_timeoutTimer.start(kTimeoutMs);
    } else {
        m_mavlink->sender()->sendMissionAck(m_targetSys, m_targetComp, MAV_MISSION_ACCEPTED);
        m_mission->setWaypoints(m_downloadBuffer);
        setState(MissionTransferState::Complete);
        emit downloadComplete();
        qCInfo(lcMission) << "Download complete, items=" << m_downloadBuffer.size();
    }
}

void MissionManager::setState(MissionTransferState s)
{
    if (m_transferState == s) return;
    m_transferState = s;
    emit transferStateChanged();
}

bool MissionManager::transferInProgress() const
{
    return m_transferState == MissionTransferState::Uploading ||
           m_transferState == MissionTransferState::Downloading ||
           m_transferState == MissionTransferState::Clearing;
}

bool MissionManager::isTargetMessage(const mavlink_message_t &msg) const
{
    return msg.sysid == m_targetSys;
}

void MissionManager::onTimeout()
{
    if (transferInProgress()) {
        setState(MissionTransferState::Failed);
        emit transferFailed("Mission operation timed out; check the vehicle connection and retry");
        qCWarning(lcMission) << "Operation timed out";
    }
}

} // namespace IndigenousGCS
