#include "Vehicle.h"
#include "Telemetry.h"
#include "FlightModeManager.h"
#include "mavlink/MAVLinkManager.h"
#include <QLoggingCategory>
#include <cmath>

Q_LOGGING_CATEGORY(lcVehicle, "igcs.vehicle")

namespace IndigenousGCS {

Vehicle::Vehicle(uint8_t sysId, uint8_t compId,
                 MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent)
    , m_sysId(sysId)
    , m_compId(compId)
    , m_mavlink(mavlink)
    , m_telemetry(std::make_unique<Telemetry>(this))
    , m_flightModeManager(std::make_unique<FlightModeManager>(this))
{
    m_state.sysId  = sysId;
    m_state.compId = compId;
}

bool Vehicle::armed() const
{
    return m_state.armed;
}

QString Vehicle::flightMode() const
{
    return m_state.flightMode;
}

void Vehicle::arm()
{
    qCInfo(lcVehicle) << "Sending ARM to sysId=" << m_sysId;
    m_mavlink->sendArm(m_sysId, m_compId);
}

void Vehicle::disarm()
{
    qCInfo(lcVehicle) << "Sending DISARM to sysId=" << m_sysId;
    m_mavlink->sendDisarm(m_sysId, m_compId);
}

void Vehicle::setFlightMode(const QString &modeName)
{
    const uint32_t customMode = m_flightModeManager->customModeFromName(modeName);
    const uint8_t  baseMode   = m_flightModeManager->baseModeForCustom(customMode, m_state.armed);
    qCInfo(lcVehicle) << "Setting flight mode" << modeName << "custom=" << customMode;
    m_mavlink->sendSetFlightMode(m_sysId, baseMode, customMode);
}

void Vehicle::requestParameters()
{
    m_mavlink->sender()->sendParamRequestList(m_sysId, m_compId);
}

void Vehicle::requestMission()
{
    m_mavlink->sender()->sendMissionRequestList(m_sysId, m_compId);
}

void Vehicle::setConnected(bool connected)
{
    if (m_connected == connected) return;
    m_connected = connected;
    emit connectedChanged();
}

void Vehicle::handleMessage(const mavlink_message_t &msg)
{
    if (msg.sysid != m_sysId) return;

    switch (msg.msgid) {
    case MAVLINK_MSG_ID_HEARTBEAT:        processHeartbeat(msg);      break;
    case MAVLINK_MSG_ID_ATTITUDE:         processAttitude(msg);       break;
    case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: processGlobalPosition(msg); break;
    case MAVLINK_MSG_ID_GPS_RAW_INT:      processGpsRaw(msg);         break;
    case MAVLINK_MSG_ID_VFR_HUD:          processVfrHud(msg);         break;
    case MAVLINK_MSG_ID_SYS_STATUS:       processSysStatus(msg);      break;
    case MAVLINK_MSG_ID_BATTERY_STATUS:   processBatteryStatus(msg);  break;
    case MAVLINK_MSG_ID_STATUSTEXT:       processStatusText(msg);     break;
    case MAVLINK_MSG_ID_HOME_POSITION:    processHomePosition(msg);   break;
    case MAVLINK_MSG_ID_COMMAND_ACK:      processCommandAck(msg);     break;
    default: break;
    }
}

void Vehicle::processHeartbeat(const mavlink_message_t &msg)
{
    mavlink_heartbeat_t hb;
    mavlink_msg_heartbeat_decode(&msg, &hb);

    const bool wasArmed = m_state.armed;
    const QString oldMode = m_state.flightMode;

    m_state.vehicleType   = hb.type;
    m_state.autopilot     = hb.autopilot;
    m_state.baseMode      = hb.base_mode;
    m_state.customMode    = hb.custom_mode;
    m_state.systemStatus  = hb.system_status;
    m_state.armed         = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
    m_state.flightMode    = m_flightModeManager->modeNameFromCustom(hb.custom_mode);
    m_state.lastHeartbeat = QDateTime::currentDateTimeUtc();

    if (m_state.armed != wasArmed)       emit armedChanged();
    if (m_state.flightMode != oldMode)   emit flightModeChanged();

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processAttitude(const mavlink_message_t &msg)
{
    mavlink_attitude_t att;
    mavlink_msg_attitude_decode(&msg, &att);

    m_state.roll       = att.roll;
    m_state.pitch      = att.pitch;
    m_state.yaw        = att.yaw;
    m_state.rollSpeed  = att.rollspeed;
    m_state.pitchSpeed = att.pitchspeed;
    m_state.yawSpeed   = att.yawspeed;

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processGlobalPosition(const mavlink_message_t &msg)
{
    mavlink_global_position_int_t pos;
    mavlink_msg_global_position_int_decode(&msg, &pos);

    m_state.latitude    = pos.lat  / 1e7;
    m_state.longitude   = pos.lon  / 1e7;
    m_state.altitudeMSL = pos.alt  / 1000.0;
    m_state.altitudeRel = pos.relative_alt / 1000.0;
    m_state.heading     = pos.hdg  / 100.0f;

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processGpsRaw(const mavlink_message_t &msg)
{
    mavlink_gps_raw_int_t gps;
    mavlink_msg_gps_raw_int_decode(&msg, &gps);

    m_state.gpsFixType  = gps.fix_type;
    m_state.gpsSatCount = gps.satellites_visible;
    m_state.hdop        = gps.eph / 100.0f;
    m_state.vdop        = gps.epv / 100.0f;

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processVfrHud(const mavlink_message_t &msg)
{
    mavlink_vfr_hud_t hud;
    mavlink_msg_vfr_hud_decode(&msg, &hud);

    m_state.airSpeed    = hud.airspeed;
    m_state.groundSpeed = hud.groundspeed;
    m_state.heading     = static_cast<float>(hud.heading);
    m_state.climbRate   = hud.climb;

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processSysStatus(const mavlink_message_t &msg)
{
    mavlink_sys_status_t sys;
    mavlink_msg_sys_status_decode(&msg, &sys);

    m_state.sensorsPresentBitmask = static_cast<uint16_t>(sys.onboard_control_sensors_present);
    m_state.sensorsEnabledBitmask = static_cast<uint16_t>(sys.onboard_control_sensors_enabled);
    m_state.sensorsHealthBitmask  = static_cast<uint16_t>(sys.onboard_control_sensors_health);
    m_state.cpuLoad               = sys.load;
    m_state.batteryVoltage        = sys.voltage_battery / 1000.0f;
    m_state.batteryCurrent        = sys.current_battery / 100.0f;
    m_state.batteryRemaining      = sys.battery_remaining;

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processBatteryStatus(const mavlink_message_t &msg)
{
    mavlink_battery_status_t bat;
    mavlink_msg_battery_status_decode(&msg, &bat);

    // Use first cell voltage sum if sys_status didn't provide it
    if (m_state.batteryVoltage < 0.1f && bat.voltages[0] != UINT16_MAX) {
        float total = 0.0f;
        int cells = 0;
        for (int i = 0; i < 10; ++i) {
            if (bat.voltages[i] != UINT16_MAX) { total += bat.voltages[i]; ++cells; }
        }
        if (cells > 0) m_state.batteryVoltage = total / 1000.0f;
    }
    if (bat.battery_remaining >= 0)
        m_state.batteryRemaining = bat.battery_remaining;

    m_telemetry->update(m_state);
    emit telemetryUpdated();
}

void Vehicle::processStatusText(const mavlink_message_t &msg)
{
    mavlink_statustext_t st;
    mavlink_msg_statustext_decode(&msg, &st);
    char text[51] = {};
    strncpy(text, st.text, 50);
    emit statusTextReceived(st.severity, QString::fromUtf8(text));
}

void Vehicle::processHomePosition(const mavlink_message_t &msg)
{
    mavlink_home_position_t home;
    mavlink_msg_home_position_decode(&msg, &home);

    m_state.homeSet = true;
    m_state.homeLat = home.latitude  / 1e7;
    m_state.homeLon = home.longitude / 1e7;
    m_state.homeAlt = home.altitude  / 1000.0;
}

void Vehicle::processCommandAck(const mavlink_message_t &msg)
{
    mavlink_command_ack_t ack;
    mavlink_msg_command_ack_decode(&msg, &ack);
    emit commandAckReceived(ack.command, ack.result);
}

} // namespace IndigenousGCS
