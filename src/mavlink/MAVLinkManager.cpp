#include "MAVLinkManager.h"
#include "MAVLinkParser.h"
#include "MAVLinkSender.h"
#include "app/AppSettings.h"
#include <QLoggingCategory>
#include <cstring>

Q_LOGGING_CATEGORY(lcMAVLink, "igcs.mavlink")

namespace IndigenousGCS {

MAVLinkManager::MAVLinkManager(AppSettings *settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
    , m_parser(std::make_unique<MAVLinkParser>(this))
    , m_sender(std::make_unique<MAVLinkSender>(this))
{
    m_sender->setSystemId(static_cast<uint8_t>(settings->gcsSystemId()));
    m_sender->setComponentId(static_cast<uint8_t>(settings->gcsComponentId()));

    connect(m_parser.get(), &MAVLinkParser::messageReceived,
            this, &MAVLinkManager::onMessageReceived);
    connect(m_sender.get(), &MAVLinkSender::bytesToSend,
            this, &MAVLinkManager::bytesToSend);

    m_heartbeatTxTimer.setInterval(kHeartbeatTxIntervalMs);
    connect(&m_heartbeatTxTimer, &QTimer::timeout, this, [this]() {
        m_sender->sendHeartbeat();
    });
    m_heartbeatTxTimer.start();

    m_heartbeatRxTimer.setInterval(kHeartbeatTimeoutMs);
    connect(&m_heartbeatRxTimer, &QTimer::timeout, this, &MAVLinkManager::onHeartbeatTimer);
    m_heartbeatRxTimer.start();

    m_statsTimer.setInterval(kStatsIntervalMs);
    connect(&m_statsTimer, &QTimer::timeout, this, &MAVLinkManager::onStatsTimer);
    m_statsTimer.start();
}

void MAVLinkManager::processBytes(const QByteArray &data)
{
    m_parser->parseBytes(data);
}

void MAVLinkManager::processSimulationBytes(const QByteArray &data)
{
    m_processingSimulationBytes = true;
    m_parser->parseBytes(data);
    m_processingSimulationBytes = false;
}

void MAVLinkManager::sendArm(uint8_t targetSys, uint8_t targetComp, bool force)
{
    m_sender->sendCommandLong(targetSys, targetComp,
                              MAV_CMD_COMPONENT_ARM_DISARM,
                              1.0f,                          // arm
                              force ? 21196.0f : 0.0f);      // force flag
}

void MAVLinkManager::sendDisarm(uint8_t targetSys, uint8_t targetComp, bool force)
{
    m_sender->sendCommandLong(targetSys, targetComp,
                              MAV_CMD_COMPONENT_ARM_DISARM,
                              0.0f,
                              force ? 21196.0f : 0.0f);
}

void MAVLinkManager::sendSetFlightMode(uint8_t targetSys, uint8_t baseMode, uint32_t customMode)
{
    m_sender->sendSetMode(targetSys, baseMode, customMode);
}

void MAVLinkManager::onMessageReceived(const mavlink_message_t &msg)
{
    emit messageReceived(msg);

    if (msg.msgid == MAVLINK_MSG_ID_HEARTBEAT) {
        handleHeartbeat(msg);
        emit heartbeatReceived();
    }

    if (msg.msgid == MAVLINK_MSG_ID_COMMAND_ACK) {
        mavlink_command_ack_t ack;
        mavlink_msg_command_ack_decode(&msg, &ack);
        emit commandAcknowledged(ack.command, ack.result);
        qCDebug(lcMAVLink) << "CMD_ACK cmd=" << ack.command << "result=" << ack.result;
    }

    if (msg.msgid == MAVLINK_MSG_ID_STATUSTEXT) {
        mavlink_statustext_t st;
        mavlink_msg_statustext_decode(&msg, &st);
        char text[51] = {};
        strncpy(text, st.text, 50);

        QVariantMap entry;
        entry[QStringLiteral("severity")] = static_cast<int>(st.severity);
        entry[QStringLiteral("text")]     = QString::fromUtf8(text);
        entry[QStringLiteral("time")]     = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

        // Keep only last kMaxStatusMessages
        if (m_statusMessages.size() >= kMaxStatusMessages)
            m_statusMessages.removeFirst();
        m_statusMessages.append(entry);
        emit statusMessageAdded();
    }
}

void MAVLinkManager::handleHeartbeat(const mavlink_message_t &msg)
{
    mavlink_heartbeat_t hb;
    mavlink_msg_heartbeat_decode(&msg, &hb);

    // Ignore GCS heartbeats
    if (hb.type == MAV_TYPE_GCS) return;

    const bool isNew = !m_vehicles.contains(msg.sysid);
    const bool wasSimulated = m_simulatedVehicles.contains(msg.sysid);

    HeartbeatInfo &info = m_vehicles[msg.sysid];
    info.sysId        = msg.sysid;
    info.compId       = msg.compid;
    info.type         = hb.type;
    info.autopilot    = hb.autopilot;
    info.baseMode     = hb.base_mode;
    info.customMode   = hb.custom_mode;
    info.systemStatus = hb.system_status;
    info.lastSeen     = QDateTime::currentDateTimeUtc();
    if (m_processingSimulationBytes)
        m_simulatedVehicles.insert(msg.sysid);
    else
        m_simulatedVehicles.remove(msg.sysid);
    const bool isSimulated = m_simulatedVehicles.contains(msg.sysid);

    if (isNew) {
        m_hasVehicle = true;
        m_hasPhysicalVehicle = !m_simulatedVehicles.isEmpty()
                ? m_simulatedVehicles.size() < m_vehicles.size()
                : true;
        qCInfo(lcMAVLink) << (m_simulatedVehicles.contains(msg.sysid)
                              ? "Simulated vehicle detected sysId="
                              : "Flight controller detected sysId=")
                          << msg.sysid << "type=" << hb.type;
        emit vehicleDetected(msg.sysid, msg.compid, isSimulated);
        emit vehicleAvailabilityChanged();
    } else if (wasSimulated != isSimulated) {
        emit vehicleSourceChanged(msg.sysid, isSimulated);
        m_hasPhysicalVehicle = m_vehicles.size() > m_simulatedVehicles.size();
        emit vehicleAvailabilityChanged();
    }
}

void MAVLinkManager::onHeartbeatTimer()
{
    const QDateTime now = QDateTime::currentDateTimeUtc();
    QList<uint8_t> lost;
    for (auto it = m_vehicles.begin(); it != m_vehicles.end(); ++it) {
        if (it->lastSeen.msecsTo(now) > kHeartbeatTimeoutMs)
            lost.append(it.key());
    }
    for (uint8_t sysId : lost) {
        m_vehicles.remove(sysId);
        m_simulatedVehicles.remove(sysId);
        qCWarning(lcMAVLink) << "Vehicle lost sysId=" << sysId;
        emit vehicleLost(sysId);
    }
    m_hasVehicle = !m_vehicles.isEmpty();
    m_hasPhysicalVehicle = m_vehicles.size() > m_simulatedVehicles.size();
    emit vehicleAvailabilityChanged();
}

void MAVLinkManager::onStatsTimer()
{
    const quint64 current = m_parser->totalReceived();
    m_packetsPerSec = static_cast<double>(current - m_lastPacketCount);
    m_lastPacketCount = current;
    emit statsUpdated();
}

} // namespace IndigenousGCS
