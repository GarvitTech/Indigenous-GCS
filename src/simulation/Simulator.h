#pragma once
#include <QObject>
#include <QTimer>
#include <QByteArray>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

namespace IndigenousGCS {

enum class SimState { Idle, TakingOff, Flying, Landing, Landed };

class Simulator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool    running   READ running   NOTIFY runningChanged)
    Q_PROPERTY(QString simState  READ simStateString NOTIFY simStateChanged)

public:
    explicit Simulator(QObject *parent = nullptr);

    bool    running()       const { return m_running; }
    QString simStateString() const;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void arm();
    Q_INVOKABLE void disarm();
    Q_INVOKABLE void takeoff(float altitudeM = 10.0f);
    Q_INVOKABLE void land();

signals:
    void bytesGenerated(const QByteArray &data);
    void runningChanged();
    void simStateChanged();

private slots:
    void tick();

private:
    void sendHeartbeat();
    void sendAttitude();
    void sendGlobalPosition();
    void sendGpsRaw();
    void sendVfrHud();
    void sendSysStatus();
    void sendBatteryStatus();
    void packAndEmit(mavlink_message_t &msg);

    QTimer   m_timer;
    bool     m_running  = false;
    bool     m_armed    = false;
    SimState m_simState = SimState::Idle;

    // Simulated state
    double  m_lat       = 28.6139;   // New Delhi default
    double  m_lon       = 77.2090;
    float   m_altMSL    = 216.0f;
    float   m_altRel    = 0.0f;
    float   m_targetAlt = 0.0f;
    float   m_roll      = 0.0f;
    float   m_pitch     = 0.0f;
    float   m_yaw       = 0.0f;
    float   m_groundSpd = 0.0f;
    float   m_climbRate = 0.0f;
    float   m_heading   = 0.0f;
    float   m_battV     = 12.6f;
    int     m_battPct   = 100;
    uint32_t m_customMode = 0;  // Stabilize
    uint32_t m_tickCount  = 0;

    static constexpr uint8_t kSysId  = 1;
    static constexpr uint8_t kCompId = 1;
    static constexpr int     kTickMs = 100;
};

} // namespace IndigenousGCS
