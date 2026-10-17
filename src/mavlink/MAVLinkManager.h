#pragma once
#include <QObject>
#include <QTimer>
#include <QDateTime>
#include <QByteArray>
#include <QHash>
#include <QSet>
#include <QVariantList>
#include <QVariantMap>
#include "MAVLinkParser.h"
#include "MAVLinkSender.h"

namespace IndigenousGCS {

class AppSettings;

struct HeartbeatInfo {
    uint8_t  sysId       = 0;
    uint8_t  compId      = 0;
    uint8_t  type        = 0;
    uint8_t  autopilot   = 0;
    uint8_t  baseMode    = 0;
    uint32_t customMode  = 0;
    uint8_t  systemStatus = 0;
    QDateTime lastSeen;
};

class MAVLinkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool   hasVehicle       READ hasVehicle       NOTIFY vehicleAvailabilityChanged)
    Q_PROPERTY(bool   hasPhysicalVehicle READ hasPhysicalVehicle NOTIFY vehicleAvailabilityChanged)
    Q_PROPERTY(double packetsPerSecond READ packetsPerSecond NOTIFY statsUpdated)
    Q_PROPERTY(double droppedPackets   READ droppedPackets   NOTIFY statsUpdated)
    Q_PROPERTY(quint64 totalPackets    READ totalPackets     NOTIFY statsUpdated)
    Q_PROPERTY(QVariantList statusMessages READ statusMessages NOTIFY statusMessageAdded)

public:
    explicit MAVLinkManager(AppSettings *settings, QObject *parent = nullptr);

    bool   hasVehicle()       const { return m_hasVehicle; }
    bool   hasPhysicalVehicle() const { return m_hasPhysicalVehicle; }
    double packetsPerSecond() const { return m_packetsPerSec; }
    double droppedPackets()   const { return static_cast<double>(m_parser->totalDropped()); }
    quint64 totalPackets()    const { return m_parser->totalReceived(); }
    QVariantList statusMessages() const { return m_statusMessages; }

    MAVLinkSender *sender() const { return m_sender.get(); }

    // Arm / Disarm
    void sendArm(uint8_t targetSys, uint8_t targetComp, bool force = false);
    void sendDisarm(uint8_t targetSys, uint8_t targetComp, bool force = false);

    // Flight mode
    void sendSetFlightMode(uint8_t targetSys, uint8_t baseMode, uint32_t customMode);

public slots:
    void processBytes(const QByteArray &data);
    void processSimulationBytes(const QByteArray &data);

signals:
    void bytesToSend(const QByteArray &data);
    void messageReceived(const mavlink_message_t &msg);
    void vehicleDetected(uint8_t sysId, uint8_t compId, bool simulated);
    void vehicleLost(uint8_t sysId);
    void vehicleSourceChanged(uint8_t sysId, bool simulated);
    void vehicleAvailabilityChanged();
    void commandAcknowledged(uint16_t command, uint8_t result);
    void statsUpdated();
    void statusMessageAdded();
    void heartbeatReceived();

private slots:
    void onMessageReceived(const mavlink_message_t &msg);
    void onHeartbeatTimer();
    void onStatsTimer();

private:
    void handleHeartbeat(const mavlink_message_t &msg);

    AppSettings                    *m_settings;
    std::unique_ptr<MAVLinkParser>  m_parser;
    std::unique_ptr<MAVLinkSender>  m_sender;

    QHash<uint8_t, HeartbeatInfo>   m_vehicles;
    QSet<uint8_t>                   m_simulatedVehicles;
    bool                            m_hasVehicle    = false;
    bool                            m_hasPhysicalVehicle = false;
    bool                            m_processingSimulationBytes = false;

    QTimer  m_heartbeatTxTimer;   // Send GCS heartbeat
    QTimer  m_heartbeatRxTimer;   // Check for vehicle heartbeat timeout
    QTimer  m_statsTimer;

    quint64 m_lastPacketCount   = 0;
    double  m_packetsPerSec     = 0.0;

    QVariantList m_statusMessages;  // ring-buffer of last 200 STATUSTEXT messages
    static constexpr int kMaxStatusMessages = 200;

    static constexpr int kHeartbeatTxIntervalMs  = 1000;
    static constexpr int kHeartbeatTimeoutMs      = 5000;
    static constexpr int kStatsIntervalMs         = 1000;
};

} // namespace IndigenousGCS
