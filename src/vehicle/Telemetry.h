#pragma once
#include <QObject>
#include <QString>
#include "VehicleState.h"

namespace IndigenousGCS {

class Telemetry : public QObject
{
    Q_OBJECT

    // Attitude
    Q_PROPERTY(float  roll        READ roll        NOTIFY attitudeChanged)
    Q_PROPERTY(float  pitch       READ pitch       NOTIFY attitudeChanged)
    Q_PROPERTY(float  yaw         READ yaw         NOTIFY attitudeChanged)
    Q_PROPERTY(float  heading     READ heading     NOTIFY attitudeChanged)

    // Position
    Q_PROPERTY(double latitude    READ latitude    NOTIFY positionChanged)
    Q_PROPERTY(double longitude   READ longitude   NOTIFY positionChanged)
    Q_PROPERTY(double altitudeMSL READ altitudeMSL NOTIFY positionChanged)
    Q_PROPERTY(double altitudeRel READ altitudeRel NOTIFY positionChanged)

    // Speed
    Q_PROPERTY(float  groundSpeed READ groundSpeed NOTIFY speedChanged)
    Q_PROPERTY(float  airSpeed    READ airSpeed    NOTIFY speedChanged)
    Q_PROPERTY(float  climbRate   READ climbRate   NOTIFY speedChanged)

    // GPS
    Q_PROPERTY(int    gpsFixType  READ gpsFixType  NOTIFY gpsChanged)
    Q_PROPERTY(int    gpsSatCount READ gpsSatCount NOTIFY gpsChanged)
    Q_PROPERTY(float  hdop        READ hdop        NOTIFY gpsChanged)

    // Battery
    Q_PROPERTY(float  batteryVoltage   READ batteryVoltage   NOTIFY batteryChanged)
    Q_PROPERTY(float  batteryCurrent   READ batteryCurrent   NOTIFY batteryChanged)
    Q_PROPERTY(int    batteryRemaining READ batteryRemaining NOTIFY batteryChanged)

    // State
    Q_PROPERTY(bool    armed       READ armed       NOTIFY stateChanged)
    Q_PROPERTY(QString flightMode  READ flightMode  NOTIFY stateChanged)
    Q_PROPERTY(int     cpuLoad     READ cpuLoad     NOTIFY stateChanged)

    // RC
    Q_PROPERTY(int     rcRSSI      READ rcRSSI      NOTIFY rcChanged)

public:
    explicit Telemetry(QObject *parent = nullptr);

    void update(const VehicleState &state);

    float  roll()        const { return m_state.roll  * 57.2958f; }
    float  pitch()       const { return m_state.pitch * 57.2958f; }
    float  yaw()         const { return m_state.yaw   * 57.2958f; }
    float  heading()     const { return m_state.heading; }

    double latitude()    const { return m_state.latitude; }
    double longitude()   const { return m_state.longitude; }
    double altitudeMSL() const { return m_state.altitudeMSL; }
    double altitudeRel() const { return m_state.altitudeRel; }

    float  groundSpeed() const { return m_state.groundSpeed; }
    float  airSpeed()    const { return m_state.airSpeed; }
    float  climbRate()   const { return m_state.climbRate; }

    int    gpsFixType()  const { return m_state.gpsFixType; }
    int    gpsSatCount() const { return m_state.gpsSatCount; }
    float  hdop()        const { return m_state.hdop; }

    float  batteryVoltage()   const { return m_state.batteryVoltage; }
    float  batteryCurrent()   const { return m_state.batteryCurrent; }
    int    batteryRemaining() const { return m_state.batteryRemaining; }

    bool    armed()      const { return m_state.armed; }
    QString flightMode() const { return m_state.flightMode; }
    int     cpuLoad()    const { return m_state.cpuLoad; }
    int     rcRSSI()     const { return static_cast<int>(m_state.rcRssi); }

    const VehicleState &state() const { return m_state; }

signals:
    void attitudeChanged();
    void positionChanged();
    void speedChanged();
    void gpsChanged();
    void batteryChanged();
    void stateChanged();
    void rcChanged();

private:
    VehicleState m_state;
};

} // namespace IndigenousGCS
