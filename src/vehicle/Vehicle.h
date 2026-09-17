#pragma once
#include <QObject>
#include <QString>
#include <memory>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"
#include "VehicleState.h"
#include "Telemetry.h"
#include "FlightModeManager.h"

namespace IndigenousGCS {

class MAVLinkManager;

class Vehicle : public QObject
{
    Q_OBJECT
    Q_PROPERTY(uint8_t  sysId       READ sysId       CONSTANT)
    Q_PROPERTY(bool     armed       READ armed       NOTIFY armedChanged)
    Q_PROPERTY(QString  flightMode  READ flightMode  NOTIFY flightModeChanged)
    Q_PROPERTY(bool     connected   READ connected   NOTIFY connectedChanged)

public:
    explicit Vehicle(uint8_t sysId, uint8_t compId,
                     MAVLinkManager *mavlink, QObject *parent = nullptr);

    uint8_t  sysId()      const { return m_sysId; }
    uint8_t  compId()     const { return m_compId; }
    bool     armed()      const;
    QString  flightMode() const;
    bool     connected()  const { return m_connected; }

    Telemetry         *telemetry()         const { return m_telemetry.get(); }
    FlightModeManager *flightModeManager() const { return m_flightModeManager.get(); }

    // Commands — these send real MAVLink messages
    Q_INVOKABLE void arm();
    Q_INVOKABLE void disarm();
    Q_INVOKABLE void setFlightMode(const QString &modeName);
    Q_INVOKABLE void requestParameters();
    Q_INVOKABLE void requestMission();

public slots:
    void handleMessage(const mavlink_message_t &msg);
    void setConnected(bool connected);

signals:
    void armedChanged();
    void flightModeChanged();
    void connectedChanged();
    void telemetryUpdated();
    void statusTextReceived(int severity, const QString &text);
    void commandAckReceived(uint16_t command, uint8_t result);

private:
    void processHeartbeat(const mavlink_message_t &msg);
    void processAttitude(const mavlink_message_t &msg);
    void processGlobalPosition(const mavlink_message_t &msg);
    void processGpsRaw(const mavlink_message_t &msg);
    void processVfrHud(const mavlink_message_t &msg);
    void processSysStatus(const mavlink_message_t &msg);
    void processBatteryStatus(const mavlink_message_t &msg);
    void processStatusText(const mavlink_message_t &msg);
    void processHomePosition(const mavlink_message_t &msg);
    void processCommandAck(const mavlink_message_t &msg);

    uint8_t            m_sysId;
    uint8_t            m_compId;
    bool               m_connected = false;
    MAVLinkManager    *m_mavlink;
    VehicleState       m_state;

    std::unique_ptr<Telemetry>         m_telemetry;
    std::unique_ptr<FlightModeManager> m_flightModeManager;
};

} // namespace IndigenousGCS
