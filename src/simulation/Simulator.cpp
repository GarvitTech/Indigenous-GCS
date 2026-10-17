#include "Simulator.h"
#include "utils/GeoUtils.h"
#include <cmath>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcSim, "igcs.simulator")

namespace IndigenousGCS {

// Pi from the shared utility rather than M_PI, which MSVC does not define.
using GeoUtils::kPi;

// Static constexpr member definition
constexpr Simulator::WP Simulator::kWaypoints[3];

Simulator::Simulator(QObject *parent) : QObject(parent)
{
    m_timer.stop();
    m_timer.setInterval(kTickMs);  // 20 Hz
    connect(&m_timer, &QTimer::timeout, this, &Simulator::tick);
    qCInfo(lcSim) << "Simulator initialized (stopped); starts only on explicit request";
}

QString Simulator::simStateString() const
{
    switch (m_simState) {
    case SimState::Idle:      return "Idle";
    case SimState::TakingOff: return "Taking Off";
    case SimState::Flying:    return "Flying";
    case SimState::Landing:   return "Landing";
    case SimState::Landed:    return "Landed";
    }
    return "Unknown";
}

QString Simulator::simulationPhase() const
{
    switch (m_phase) {
    case SimPhase::Idle:      return "Idle";
    case SimPhase::TakingOff: return "Takeoff";
    case SimPhase::Waypoint1: return "Waypoint 1";
    case SimPhase::Waypoint2: return "Waypoint 2";
    case SimPhase::Waypoint3: return "Waypoint 3";
    case SimPhase::Hold:      return "Hold";
    case SimPhase::RTL:       return "RTL";
    case SimPhase::Landing:   return "Landing";
    case SimPhase::Landed:    return "Landed";
    }
    return "Unknown";
}

void Simulator::start()
{
    if (m_running) return;
    m_running = true;
    resetMission();
    m_timer.start();
    emit runningChanged();
    qCInfo(lcSim) << "Simulator started (20 Hz auto-pilot mission)";
}

void Simulator::stop()
{
    if (!m_running) return;
    m_running  = false;
    m_armed    = false;
    m_simState = SimState::Idle;
    m_phase    = SimPhase::Idle;
    m_timer.stop();
    emit runningChanged();
    emit simStateChanged();
    emit simulationPhaseChanged();
}

void Simulator::arm()
{
    m_armed = true;
    qCInfo(lcSim) << "Simulator armed";
}

void Simulator::disarm()
{
    m_armed    = false;
    m_simState = SimState::Idle;
    m_phase    = SimPhase::Idle;
    emit simStateChanged();
    emit simulationPhaseChanged();
}

void Simulator::takeoff(float altitudeM)
{
    if (!m_armed) return;
    m_targetAlt  = altitudeM;
    m_simState   = SimState::TakingOff;
    m_phase      = SimPhase::TakingOff;
    m_customMode = 4; // Guided
    emit simStateChanged();
    emit simulationPhaseChanged();
}

void Simulator::land()
{
    m_simState   = SimState::Landing;
    m_phase      = SimPhase::Landing;
    m_targetAlt  = 0.0f;
    m_customMode = 9; // Land
    emit simStateChanged();
    emit simulationPhaseChanged();
}

void Simulator::resetMission()
{
    m_lat          = m_homeLat;
    m_lon          = m_homeLon;
    m_altMSL       = 216.0f;
    m_altRel       = 0.0f;
    m_roll         = 0.0f;
    m_pitch        = 0.0f;
    m_yaw          = 0.0f;
    m_groundSpd    = 0.0f;
    m_climbRate    = 0.0f;
    m_heading      = 0.0f;
    m_battV        = 12.6f;
    m_battPct      = 100;
    m_progress     = 0.0;
    m_customMode   = 0;
    m_tickCount    = 0;
    m_phaseTickCount = 0;
    m_cycleTicks   = 0;
    m_armed        = false;
    m_phase        = SimPhase::Idle;
    m_simState     = SimState::Idle;
}

void Simulator::tick()
{
    ++m_tickCount;
    ++m_cycleTicks;

    advanceAutoPilot();

    // Update progress (0–1)
    double newProgress = static_cast<double>(m_cycleTicks) / kTotalCycleTicks;
    if (newProgress > 1.0) newProgress = 1.0;
    if (qAbs(newProgress - m_progress) > 0.001) {
        m_progress = newProgress;
        emit progressChanged();
    }

    // Battery drains from 100% to 85% over the full cycle
    // That's 15% over kTotalCycleTicks ticks
    double battDecay = 15.0 / kTotalCycleTicks;  // % per tick
    double newBattPct = 100.0 - battDecay * m_cycleTicks;
    m_battPct = static_cast<int>(qBound(85.0, newBattPct, 100.0));
    m_battV   = 10.0f + (m_battPct / 100.0f) * 2.6f;

    // Send messages at different rates
    sendHeartbeat();          // every tick
    sendAttitude();           // 20 Hz (every tick)
    if (m_tickCount % 4 == 0) sendGlobalPosition(); // 5 Hz
    if (m_tickCount % 4 == 0) sendGpsRaw();          // 5 Hz
    if (m_tickCount % 4 == 0) sendVfrHud();           // 5 Hz
    if (m_tickCount % 20 == 0) sendSysStatus();       // 1 Hz
    if (m_tickCount % 20 == 0) sendBatteryStatus();   // 1 Hz
}

void Simulator::advanceAutoPilot()
{
    ++m_phaseTickCount;
    const float dt = kTickMs / 1000.0f;

    switch (m_phase) {

    case SimPhase::Idle: {
        // Stay idle for 1 second (20 ticks), then arm and takeoff
        if (m_phaseTickCount >= 20) {
            m_armed      = true;
            m_phase      = SimPhase::TakingOff;
            m_simState   = SimState::TakingOff;
            m_targetAlt  = 100.0f;
            m_customMode = 4; // Guided
            m_phaseTickCount = 0;
            sendStatusText("Takeoff");
            emit simStateChanged();
            emit simulationPhaseChanged();
        }
        break;
    }

    case SimPhase::TakingOff: {
        // Climb to 100m AGL over 10 seconds = 200 ticks at 20Hz
        // Rate = 100m / 10s = 10 m/s
        m_climbRate = 10.0f;
        m_altRel   += m_climbRate * dt;
        m_altMSL   += m_climbRate * dt;
        m_pitch     = 15.0f;  // nose up during climb
        if (m_altRel >= m_targetAlt || m_phaseTickCount >= 200) {
            m_altRel     = m_targetAlt;
            m_altMSL     = 216.0f + m_targetAlt;
            m_climbRate  = 0.0f;
            m_pitch      = 0.0f;
            m_phase      = SimPhase::Waypoint1;
            m_simState   = SimState::Flying;
            m_customMode = 3; // Auto
            m_phaseTickCount = 0;
            sendStatusText("Waypoint 1 reached");
            emit simStateChanged();
            emit simulationPhaseChanged();
        }
        break;
    }

    case SimPhase::Waypoint1: {
        // Fly toward waypoint 1 over ~100 ticks (5 seconds)
        const WP &wp = kWaypoints[0];
        double dLat  = wp.lat - m_lat;
        double dLon  = wp.lon - m_lon;
        double dist  = std::sqrt(dLat*dLat*111000.0*111000.0 + dLon*dLon*96000.0*96000.0);

        if (dist < 20.0 || m_phaseTickCount >= 100) {
            m_lat   = wp.lat;
            m_lon   = wp.lon;
            m_phase = SimPhase::Waypoint2;
            m_phaseTickCount = 0;
            sendStatusText("Waypoint 2 reached");
            emit simulationPhaseChanged();
        } else {
            double speed = 10.0;  // m/s
            double stepM = speed * dt;
            double bearing = std::atan2(dLon * 96000.0, dLat * 111000.0);
            m_lat += (stepM / 111000.0) * std::cos(bearing);
            m_lon += (stepM / 96000.0)  * std::sin(bearing);
            m_groundSpd = static_cast<float>(speed);
            m_heading   = static_cast<float>(bearing * GeoUtils::kRadToDeg);
            if (m_heading < 0) m_heading += 360.0f;
            m_yaw   = m_heading;
            m_roll  = 5.0f * std::sin(m_phaseTickCount * 0.1f);
            m_pitch = 2.0f;
        }
        break;
    }

    case SimPhase::Waypoint2: {
        const WP &wp = kWaypoints[1];
        double dLat  = wp.lat - m_lat;
        double dLon  = wp.lon - m_lon;
        double dist  = std::sqrt(dLat*dLat*111000.0*111000.0 + dLon*dLon*96000.0*96000.0);

        if (dist < 20.0 || m_phaseTickCount >= 100) {
            m_lat   = wp.lat;
            m_lon   = wp.lon;
            m_phase = SimPhase::Waypoint3;
            m_phaseTickCount = 0;
            sendStatusText("Waypoint 3 reached");
            emit simulationPhaseChanged();
        } else {
            double speed = 10.0;
            double stepM = speed * dt;
            double bearing = std::atan2(dLon * 96000.0, dLat * 111000.0);
            m_lat += (stepM / 111000.0) * std::cos(bearing);
            m_lon += (stepM / 96000.0)  * std::sin(bearing);
            m_groundSpd = static_cast<float>(speed);
            m_heading   = static_cast<float>(bearing * GeoUtils::kRadToDeg);
            if (m_heading < 0) m_heading += 360.0f;
            m_yaw   = m_heading;
            m_roll  = 5.0f * std::sin(m_phaseTickCount * 0.1f);
            m_pitch = 2.0f;
        }
        break;
    }

    case SimPhase::Waypoint3: {
        const WP &wp = kWaypoints[2];
        double dLat  = wp.lat - m_lat;
        double dLon  = wp.lon - m_lon;
        double dist  = std::sqrt(dLat*dLat*111000.0*111000.0 + dLon*dLon*96000.0*96000.0);

        if (dist < 20.0 || m_phaseTickCount >= 100) {
            m_lat   = wp.lat;
            m_lon   = wp.lon;
            m_phase = SimPhase::Hold;
            m_phaseTickCount = 0;
            sendStatusText("Holding at last waypoint");
            emit simulationPhaseChanged();
        } else {
            double speed = 10.0;
            double stepM = speed * dt;
            double bearing = std::atan2(dLon * 96000.0, dLat * 111000.0);
            m_lat += (stepM / 111000.0) * std::cos(bearing);
            m_lon += (stepM / 96000.0)  * std::sin(bearing);
            m_groundSpd = static_cast<float>(speed);
            m_heading   = static_cast<float>(bearing * GeoUtils::kRadToDeg);
            if (m_heading < 0) m_heading += 360.0f;
            m_yaw   = m_heading;
            m_roll  = 5.0f * std::sin(m_phaseTickCount * 0.1f);
            m_pitch = 2.0f;
        }
        break;
    }

    case SimPhase::Hold: {
        // Loiter for 5 seconds = 100 ticks
        m_groundSpd = 0.0f;
        m_climbRate = 0.0f;
        m_roll  = 2.0f * std::sin(m_phaseTickCount * 0.2f);
        m_pitch = 1.0f * std::cos(m_phaseTickCount * 0.15f);
        if (m_phaseTickCount >= 100) {
            m_phase = SimPhase::RTL;
            m_phaseTickCount = 0;
            m_customMode = 11; // RTL
            sendStatusText("Returning to launch");
            emit simulationPhaseChanged();
        }
        break;
    }

    case SimPhase::RTL: {
        // Return to home over ~200 ticks (10 seconds)
        double dLat = m_homeLat - m_lat;
        double dLon = m_homeLon - m_lon;
        double dist = std::sqrt(dLat*dLat*111000.0*111000.0 + dLon*dLon*96000.0*96000.0);

        if (dist < 20.0 || m_phaseTickCount >= 200) {
            m_lat   = m_homeLat;
            m_lon   = m_homeLon;
            m_phase = SimPhase::Landing;
            m_simState   = SimState::Landing;
            m_customMode = 9; // Land
            m_phaseTickCount = 0;
            m_targetAlt = 0.0f;
            sendStatusText("Landing");
            emit simStateChanged();
            emit simulationPhaseChanged();
        } else {
            double speed = 10.0;
            double stepM = speed * dt;
            double bearing = std::atan2(dLon * 96000.0, dLat * 111000.0);
            m_lat += (stepM / 111000.0) * std::cos(bearing);
            m_lon += (stepM / 96000.0)  * std::sin(bearing);
            m_groundSpd = static_cast<float>(speed);
            m_heading   = static_cast<float>(bearing * GeoUtils::kRadToDeg);
            if (m_heading < 0) m_heading += 360.0f;
            m_yaw   = m_heading;
            m_roll  = 3.0f * std::sin(m_phaseTickCount * 0.1f);
            m_pitch = -2.0f;
        }
        break;
    }

    case SimPhase::Landing: {
        // Descend from 100m over ~100 ticks (5 seconds) → 20 m/s descent
        m_climbRate = -2.0f;
        m_altRel   += m_climbRate * dt;
        m_altMSL   += m_climbRate * dt;
        m_groundSpd = 0.5f;
        m_pitch     = -5.0f;

        if (m_altRel <= 0.0f || m_phaseTickCount >= 100) {
            m_altRel    = 0.0f;
            m_altMSL    = 216.0f;
            m_climbRate = 0.0f;
            m_pitch     = 0.0f;
            m_groundSpd = 0.0f;
            m_armed     = false;
            m_phase     = SimPhase::Landed;
            m_simState  = SimState::Landed;
            m_customMode = 0;
            m_phaseTickCount = 0;
            sendStatusText("Landed");
            emit simStateChanged();
            emit simulationPhaseChanged();
        }
        break;
    }

    case SimPhase::Landed: {
        // After landing, restart the cycle
        if (m_phaseTickCount >= 20) {
            qCInfo(lcSim) << "Mission cycle complete – restarting";
            resetMission();
            m_cycleTicks = 0;
            m_progress   = 0.0;
            emit progressChanged();
        }
        break;
    }
    }
}

void Simulator::sendHeartbeat()
{
    if (m_tickCount % 20 != 0) return; // 1 Hz from 20Hz timer
    mavlink_message_t msg;
    uint8_t baseMode = MAV_MODE_FLAG_CUSTOM_MODE_ENABLED | MAV_MODE_FLAG_STABILIZE_ENABLED;
    if (m_armed) baseMode |= MAV_MODE_FLAG_SAFETY_ARMED;
    mavlink_msg_heartbeat_pack(kSysId, kCompId, &msg,
                               MAV_TYPE_QUADROTOR,
                               MAV_AUTOPILOT_ARDUPILOTMEGA,
                               baseMode, m_customMode,
                               m_armed ? MAV_STATE_ACTIVE : MAV_STATE_STANDBY);
    packAndEmit(msg);
}

void Simulator::sendAttitude()
{
    mavlink_message_t msg;
    mavlink_msg_attitude_pack(kSysId, kCompId, &msg,
                              m_tickCount * kTickMs,
                              m_roll  * static_cast<float>(GeoUtils::kDegToRad),
                              m_pitch * static_cast<float>(GeoUtils::kDegToRad),
                              m_yaw   * static_cast<float>(GeoUtils::kDegToRad),
                              0.0f, 0.0f, 0.0f);
    packAndEmit(msg);
}

void Simulator::sendGlobalPosition()
{
    mavlink_message_t msg;
    mavlink_msg_global_position_int_pack(kSysId, kCompId, &msg,
                                         m_tickCount * kTickMs,
                                         static_cast<int32_t>(m_lat * 1e7),
                                         static_cast<int32_t>(m_lon * 1e7),
                                         static_cast<int32_t>(m_altMSL * 1000),
                                         static_cast<int32_t>(m_altRel * 1000),
                                         0, 0,
                                         static_cast<int32_t>(m_groundSpd * 100),
                                         static_cast<uint16_t>(m_heading * 100));
    packAndEmit(msg);
}

void Simulator::sendGpsRaw()
{
    mavlink_message_t msg;
    // GPS fix type 3 = 3D fix, 12 satellites, HDOP 0.9 (= 90 in units of 0.01)
    mavlink_msg_gps_raw_int_pack(kSysId, kCompId, &msg,
                                  m_tickCount * kTickMs,
                                  GPS_FIX_TYPE_3D_FIX,
                                  static_cast<int32_t>(m_lat * 1e7),
                                  static_cast<int32_t>(m_lon * 1e7),
                                  static_cast<int32_t>(m_altMSL * 1000),
                                  90,   // eph = HDOP 0.9
                                  200,  // epv
                                  static_cast<uint16_t>(m_groundSpd * 100),
                                  static_cast<uint16_t>(m_heading * 100),
                                  12,   // satellites visible
                                  0, 0, 0, 0, 0, 0);
    packAndEmit(msg);
}

void Simulator::sendVfrHud()
{
    mavlink_message_t msg;
    mavlink_msg_vfr_hud_pack(kSysId, kCompId, &msg,
                              m_groundSpd, m_groundSpd,
                              static_cast<int16_t>(m_heading),
                              m_armed ? 50 : 0,
                              m_altMSL,
                              m_climbRate);
    packAndEmit(msg);
}

void Simulator::sendSysStatus()
{
    mavlink_message_t msg;
    uint32_t sensors = MAV_SYS_STATUS_SENSOR_3D_GYRO |
                       MAV_SYS_STATUS_SENSOR_3D_ACCEL |
                       MAV_SYS_STATUS_SENSOR_3D_MAG |
                       MAV_SYS_STATUS_SENSOR_GPS;
    mavlink_msg_sys_status_pack(kSysId, kCompId, &msg,
                                 sensors, sensors, sensors,
                                 150,
                                 static_cast<uint16_t>(m_battV * 1000),
                                 -1,
                                 m_battPct,
                                 0, 0, 0, 0, 0, 0,
                                 0, 0, 0);
    packAndEmit(msg);
}

void Simulator::sendBatteryStatus()
{
    mavlink_message_t msg;
    uint16_t voltages[10];
    voltages[0] = static_cast<uint16_t>(m_battV * 1000 / 3);
    for (int i = 1; i < 10; ++i) voltages[i] = UINT16_MAX;
    uint16_t voltages_ext[4] = {0, 0, 0, 0};
    mavlink_msg_battery_status_pack(kSysId, kCompId, &msg,
                                     0,
                                     MAV_BATTERY_FUNCTION_ALL,
                                     MAV_BATTERY_TYPE_LIPO,
                                     INT16_MAX,
                                     voltages,
                                     -1,
                                     -1,
                                     -1,
                                     static_cast<int8_t>(m_battPct),
                                     0,
                                     MAV_BATTERY_CHARGE_STATE_OK,
                                     voltages_ext,
                                     0,
                                     0);
    packAndEmit(msg);
}

void Simulator::sendStatusText(const QString &text, uint8_t severity)
{
    mavlink_message_t msg;
    char buf[50] = {};
    QByteArray ba = text.toUtf8();
    strncpy(buf, ba.constData(), sizeof(buf) - 1);
    mavlink_msg_statustext_pack(kSysId, kCompId, &msg, severity, buf, 0, 0);
    packAndEmit(msg);
    qCInfo(lcSim) << "StatusText:" << text;
}

void Simulator::packAndEmit(mavlink_message_t &msg)
{
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    emit bytesGenerated(QByteArray(reinterpret_cast<const char*>(buf), len));
}

} // namespace IndigenousGCS
