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
    const QStringList errors = m_mission->validate();
    if (!errors.isEmpty()) {
        emit transferFailed("Validation: " + errors.join("; "));
        return;
    }
    m_targetSys  = targetSys;
    m_targetComp = targetComp;
    m_nextSeq    = 0;
    setState(MissionTransferState::Uploading);

    m_mavlink->sender()->sendMissionCount(targetSys, targetComp,
                                          static_cast<uint16_t>(m_mission->count()));
    m_timeoutTimer.start(kTimeoutMs);
    qCInfo(lcMission) << "Upload started, count=" << m_mission->count();
}

void MissionManager::downloadMission(uint8_t targetSys, uint8_t targetComp)
{
    m_targetSys    = targetSys;
    m_targetComp   = targetComp;
    m_downloadBuffer.clear();
    m_nextSeq      = 0;
    m_expectedCount = 0;
    setState(MissionTransferState::Downloading);

    m_mavlink->sender()->sendMissionRequestList(targetSys, targetComp);
    m_timeoutTimer.start(kTimeoutMs);
    qCInfo(lcMission) << "Download started";
}

void MissionManager::clearMission(uint8_t targetSys, uint8_t targetComp)
{
    m_mavlink->sender()->sendMissionClearAll(targetSys, targetComp);
    m_mission->clear();
}

void MissionManager::handleMessage(const mavlink_message_t &msg)
{
    switch (msg.msgid) {
    case MAVLINK_MSG_ID_MISSION_REQUEST:     handleMissionRequest(msg);    break;
    case MAVLINK_MSG_ID_MISSION_REQUEST_INT: handleMissionRequestInt(msg); break;
    case MAVLINK_MSG_ID_MISSION_ACK:         handleMissionAck(msg);        break;
    case MAVLINK_MSG_ID_MISSION_COUNT:       handleMissionCount(msg);      break;
    case MAVLINK_MSG_ID_MISSION_ITEM_INT:    handleMissionItemInt(msg);    break;
    default: break;
    }
}

void MissionManager::handleMissionRequest(const mavlink_message_t &msg)
{
    mavlink_mission_request_t req;
    mavlink_msg_mission_request_decode(&msg, &req);
    if (m_transferState != MissionTransferState::Uploading) return;
    m_nextSeq = req.seq;
    sendNextItem();
}

void MissionManager::handleMissionRequestInt(const mavlink_message_t &msg)
{
    mavlink_mission_request_int_t req;
    mavlink_msg_mission_request_int_decode(&msg, &req);
    if (m_transferState != MissionTransferState::Uploading) return;
    m_nextSeq = req.seq;
    sendNextItem();
}

void MissionManager::sendNextItem()
{
    m_timeoutTimer.start(kTimeoutMs);
    const auto &wps = m_mission->waypoints();
    if (m_nextSeq >= static_cast<uint16_t>(wps.size())) return;

    const mavlink_mission_item_int_t item = wps[m_nextSeq].toMavlinkItem();
    m_mavlink->sender()->sendMissionItemInt(m_targetSys, m_targetComp, item);

    m_transferProgress = (m_nextSeq * 100) / qMax(1, wps.size());
    emit transferProgressChanged();
    qCDebug(lcMission) << "Sent item" << m_nextSeq;
}

void MissionManager::handleMissionAck(const mavlink_message_t &msg)
{
    mavlink_mission_ack_t ack;
    mavlink_msg_mission_ack_decode(&msg, &ack);
    m_timeoutTimer.stop();

    if (ack.type == MAV_MISSION_ACCEPTED) {
        setState(MissionTransferState::Complete);
        m_transferProgress = 100;
        emit transferProgressChanged();
        if (m_transferState == MissionTransferState::Complete)
            emit uploadComplete();
        qCInfo(lcMission) << "Mission ACK accepted";
    } else {
        setState(MissionTransferState::Failed);
        emit transferFailed(QString("Mission ACK error: %1").arg(ack.type));
        qCWarning(lcMission) << "Mission ACK error" << ack.type;
    }
}

void MissionManager::handleMissionCount(const mavlink_message_t &msg)
{
    if (m_transferState != MissionTransferState::Downloading) return;
    mavlink_mission_count_t cnt;
    mavlink_msg_mission_count_decode(&msg, &cnt);
    m_expectedCount = cnt.count;
    m_nextSeq = 0;
    m_downloadBuffer.clear();

    if (m_expectedCount == 0) {
        m_mission->clear();
        setState(MissionTransferState::Complete);
        emit downloadComplete();
        return;
    }
    m_mavlink->sender()->sendMissionRequestInt(m_targetSys, m_targetComp, 0);
    m_timeoutTimer.start(kTimeoutMs);
}

void MissionManager::handleMissionItemInt(const mavlink_message_t &msg)
{
    if (m_transferState != MissionTransferState::Downloading) return;
    mavlink_mission_item_int_t item;
    mavlink_msg_mission_item_int_decode(&msg, &item);

    m_downloadBuffer.append(Waypoint::fromMavlinkItem(item));
    m_transferProgress = (m_downloadBuffer.size() * 100) / qMax(1, (int)m_expectedCount);
    emit transferProgressChanged();

    if (static_cast<uint16_t>(m_downloadBuffer.size()) < m_expectedCount) {
        m_mavlink->sender()->sendMissionRequestInt(m_targetSys, m_targetComp,
                                                   static_cast<uint16_t>(m_downloadBuffer.size()));
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

void MissionManager::onTimeout()
{
    if (m_transferState == MissionTransferState::Uploading ||
        m_transferState == MissionTransferState::Downloading) {
        setState(MissionTransferState::Failed);
        emit transferFailed("Mission transfer timed out");
        qCWarning(lcMission) << "Transfer timeout";
    }
}

} // namespace IndigenousGCS
