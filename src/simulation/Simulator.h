#pragma once
#include <QObject>
#include <QTimer>
#include <QByteArray>
#include <QString>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

namespace IndigenousGCS {

enum class SimPhase {
    Idle,
    TakingOff,
    Waypoint1,
    Waypoint2,
    Waypoint3,
    Hold,
    RTL,
    Landing,
    Landed
};

// Keep SimState for backward compat
enum class SimState { Idle, TakingOff, Flying, Landing, Landed };

class Simulator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool    running          READ running          NOTIFY runningChanged)
    Q_PROPERTY(QString simState         READ simStateString   NOTIFY simStateChanged)
    Q_PROPERTY(QString simulationPhase  READ simulationPhase  NOTIFY simulationPhaseChanged)
    Q_PROPERTY(double  progress         READ progress         NOTIFY progressChanged)

public:
    explicit Simulator(QObject *parent = nullptr);

    bool    running()          const { return m_running; }
    QString simStateString()   const;
    QString simulationPhase()  const;
    double  progress()         const { return m_progress; }

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
    void simulationPhaseChanged();
    void progressChanged();

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
    void sendStatusText(const QString &text, uint8_t severity = MAV_SEVERITY_INFO);
    void packAndEmit(mavlink_message_t &msg);

    void advanceAutoPilot();
    void resetMission();

    QTimer   m_timer;
    bool     m_running  = false;
    bool     m_armed    = false;
    SimPhase m_phase    = SimPhase::Idle;

    // For backward-compatible simState property
    SimState m_simState = SimState::Idle;

    // Simulated state
    double  m_lat        = 28.6139;   // New Delhi
    double  m_lon        = 77.2090;
    double  m_homeLat    = 28.6139;
    double  m_homeLon    = 77.2090;
    float   m_altMSL     = 216.0f;   // New Delhi approx elevation
    float   m_altRel     = 0.0f;
    float   m_targetAlt  = 0.0f;
    float   m_roll       = 0.0f;
    float   m_pitch      = 0.0f;
    float   m_yaw        = 0.0f;
    float   m_groundSpd  = 0.0f;
    float   m_climbRate  = 0.0f;
    float   m_heading    = 0.0f;
    float   m_battV      = 12.6f;
    int     m_battPct    = 100;
    double  m_progress   = 0.0;
    uint32_t m_customMode = 0;
    uint32_t m_tickCount  = 0;

    // Waypoints for triangular mission (~1km apart from New Delhi origin)
    // 1 deg lat ~ 111km, 1 deg lon ~ 96km at 28°N
    struct WP { double lat; double lon; float alt; };
    static constexpr WP kWaypoints[3] = {
        {28.6139 + 0.009, 77.2090,          116.0f},  // ~1km north
        {28.6139 + 0.009, 77.2090 + 0.010,  116.0f},  // ~1km north-east
        {28.6139,         77.2090 + 0.010,   116.0f}   // ~1km east
    };

    // Phase tick counters (at 20Hz)
    uint32_t m_phaseTickCount = 0;

    // Total estimated ticks in a full cycle for progress calculation
    // Idle(20) + Takeoff(200) + WP1(100)+WP2(100)+WP3(100) + Hold(100) + RTL(200) + Land(100) = 920
    static constexpr uint32_t kTotalCycleTicks = 920;
    uint32_t m_cycleTicks = 0;

    static constexpr uint8_t kSysId  = 250;
    static constexpr uint8_t kCompId = 1;
    static constexpr int     kTickMs = 50;  // 20Hz
};

} // namespace IndigenousGCS
