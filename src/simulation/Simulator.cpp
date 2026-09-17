#include "Simulator.h"
#include <cmath>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcSim, "igcs.simulator")

namespace IndigenousGCS {

Simulator::Simulator(QObject *parent) : QObject(parent)
{
    m_timer.setInterval(kTickMs);
    connect(&m_timer, &QTimer::timeout, this, &Simulator::tick);
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

void Simulator::start()
{
    if (m_running) return;
    m_running = true;
    m_timer.start();
    emit runningChanged();
    qCInfo(lcSim) << "Simulator started";
}

void Simulator::stop()
{
    if (!m_running) return;
    m_running = false;
    m_armed   = false;
    m_simState = SimState::Idle;
    m_timer.stop();
    emit runningChanged();
    emit simStateChanged();
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
    emit simStateChanged();
}

void Simulator::takeoff(float altitudeM)
{
    if (!m_armed) return;
    m_targetAlt = altitudeM;
    m_simState  = SimState::TakingOff;
    m_customMode = 4; // Guided
    emit simStateChanged();
}

void Simulator::land()
{
    m_simState  = SimState::Landing;
    m_targetAlt = 0.0f;
    m_customMode = 9; // Land
    emit simStateChanged();
}

void Simulator::tick()
{
    ++m_tickCount;

    // Simulate physics
    switch (m_simState) {
    case SimState::TakingOff:
        m_climbRate = 2.0f;
        m_altRel   += m_climbRate * (kTickMs / 1000.0f);
        m_altMSL   += m_climbRate * (kTickMs / 1000.0f);
        if (m_altRel >= m_targetAlt) {
            m_altRel   = m_targetAlt;
            m_climbRate = 0.0f;
            m_simState  = SimState::Flying;
            m_customMode = 5; // Loiter
            emit simStateChanged();
        }
        break;

    case SimState::Flying: {
        // Gentle circular motion
        const float t = m_tickCount * kTickMs / 1000.0f;
        m_roll      = 5.0f  * std::sin(t * 0.3f);
        m_pitch     = 3.0f  * std::cos(t * 0.2f);
        m_yaw       = std::fmod(t * 10.0f, 360.0f);
        m_heading   = m_yaw;
        m_groundSpd = 3.0f;
        m_lat      += 0.000005 * std::cos(t * 0.1f);
        m_lon      += 0.000005 * std::sin(t * 0.1f);
        // Drain battery slowly
        m_battV   -= 0.0001f;
        m_battPct  = qMax(0, static_cast<int>((m_battV - 10.0f) / 2.6f * 100));
        break;
    }

    case SimState::Landing:
        m_climbRate = -1.5f;
        m_altRel   += m_climbRate * (kTickMs / 1000.0f);
        m_altMSL   += m_climbRate * (kTickMs / 1000.0f);
        m_groundSpd = 0.0f;
        if (m_altRel <= 0.0f) {
            m_altRel    = 0.0f;
            m_climbRate = 0.0f;
            m_armed     = false;
            m_simState  = SimState::Landed;
            m_customMode = 0;
            emit simStateChanged();
        }
        break;

    default: break;
    }

    // Send messages at different rates
    sendHeartbeat();          // every tick (1 Hz effective at 10Hz tick with modulo)
    sendAttitude();           // 10 Hz
    if (m_tickCount % 2 == 0) sendGlobalPosition(); // 5 Hz
    if (m_tickCount % 2 == 0) sendGpsRaw();
    if (m_tickCount % 2 == 0) sendVfrHud();
    if (m_tickCount % 10 == 0) sendSysStatus();
    if (m_tickCount % 10 == 0) sendBatteryStatus();
}

void Simulator::sendHeartbeat()
{
    if (m_tickCount % 10 != 0) return; // 1 Hz
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
                              m_roll  * M_PI / 180.0f,
                              m_pitch * M_PI / 180.0f,
                              m_yaw   * M_PI / 180.0f,
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
    mavlink_msg_gps_raw_int_pack(kSysId, kCompId, &msg,
                                  m_tickCount * kTickMs,
                                  GPS_FIX_TYPE_3D_FIX,
                                  static_cast<int32_t>(m_lat * 1e7),
                                  static_cast<int32_t>(m_lon * 1e7),
                                  static_cast<int32_t>(m_altMSL * 1000),
                                  120, 200,
                                  static_cast<uint16_t>(m_groundSpd * 100),
                                  static_cast<uint16_t>(m_heading * 100),
                                  14,
                                  0, 0, 0, 0, 0, 0); // alt_ellipsoid, h/v/vel/hdg_acc, yaw
    packAndEmit(msg);
}

void Simulator::sendVfrHud()
{
    mavlink_message_t msg;
    mavlink_msg_vfr_hud_pack(kSysId, kCompId, &msg,
                              m_groundSpd, m_groundSpd,
                              static_cast<int16_t>(m_heading),
                              50,
                              m_altMSL, m_climbRate);
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
                                 0, 0, 0); // extended sensor fields
    packAndEmit(msg);
}

void Simulator::sendBatteryStatus()
{
    mavlink_message_t msg;
    uint16_t voltages[10];
    voltages[0] = static_cast<uint16_t>(m_battV * 1000 / 3); // 3S cell approx
    for (int i = 1; i < 10; ++i) voltages[i] = UINT16_MAX;
    uint16_t voltages_ext[4] = {0, 0, 0, 0};
    mavlink_msg_battery_status_pack(kSysId, kCompId, &msg,
                                     0,                          // id
                                     MAV_BATTERY_FUNCTION_ALL,   // battery_function
                                     MAV_BATTERY_TYPE_LIPO,      // type
                                     INT16_MAX,                  // temperature (unknown)
                                     voltages,                   // voltages[10]
                                     -1,                         // current_battery
                                     -1,                         // current_consumed
                                     -1,                         // energy_consumed
                                     static_cast<int8_t>(m_battPct), // battery_remaining
                                     0,                          // time_remaining
                                     MAV_BATTERY_CHARGE_STATE_OK,// charge_state
                                     voltages_ext,               // voltages_ext[4]
                                     0,                          // mode
                                     0);                         // fault_bitmask
    packAndEmit(msg);
}

void Simulator::packAndEmit(mavlink_message_t &msg)
{
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    emit bytesGenerated(QByteArray(reinterpret_cast<const char*>(buf), len));
}

} // namespace IndigenousGCS
