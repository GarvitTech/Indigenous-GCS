#include "MAVLinkSender.h"
#include <QByteArray>

namespace IndigenousGCS {

MAVLinkSender::MAVLinkSender(QObject *parent) : QObject(parent) {}

void MAVLinkSender::sendMessage(mavlink_message_t &msg)
{
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    emit bytesToSend(QByteArray(reinterpret_cast<const char*>(buf), len));
}

void MAVLinkSender::sendHeartbeat()
{
    mavlink_message_t msg;
    mavlink_msg_heartbeat_pack(m_sysId, m_compId, &msg,
                               MAV_TYPE_GCS,
                               MAV_AUTOPILOT_INVALID,
                               MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                               0,
                               MAV_STATE_ACTIVE);
    sendMessage(msg);
}

void MAVLinkSender::sendCommandLong(uint8_t targetSys, uint8_t targetComp,
                                    uint16_t command,
                                    float p1, float p2, float p3,
                                    float p4, float p5, float p6, float p7,
                                    uint8_t confirmation)
{
    mavlink_message_t msg;
    mavlink_msg_command_long_pack(m_sysId, m_compId, &msg,
                                  targetSys, targetComp,
                                  command, confirmation,
                                  p1, p2, p3, p4, p5, p6, p7);
    sendMessage(msg);
}

void MAVLinkSender::sendParamRequestList(uint8_t targetSys, uint8_t targetComp)
{
    mavlink_message_t msg;
    mavlink_msg_param_request_list_pack(m_sysId, m_compId, &msg, targetSys, targetComp);
    sendMessage(msg);
}

void MAVLinkSender::sendParamRequestRead(uint8_t targetSys, uint8_t targetComp,
                                         const QString &paramId, int16_t paramIndex)
{
    mavlink_message_t msg;
    char id[17] = {};
    strncpy(id, paramId.toLocal8Bit().constData(), 16);
    mavlink_msg_param_request_read_pack(m_sysId, m_compId, &msg,
                                        targetSys, targetComp, id, paramIndex);
    sendMessage(msg);
}

void MAVLinkSender::sendParamSet(uint8_t targetSys, uint8_t targetComp,
                                  const QString &paramId, float value,
                                  MAV_PARAM_TYPE type)
{
    mavlink_message_t msg;
    char id[17] = {};
    strncpy(id, paramId.toLocal8Bit().constData(), 16);
    mavlink_msg_param_set_pack(m_sysId, m_compId, &msg,
                               targetSys, targetComp, id, value, type);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionCount(uint8_t targetSys, uint8_t targetComp, uint16_t count)
{
    mavlink_message_t msg;
    mavlink_msg_mission_count_pack(m_sysId, m_compId, &msg,
                                   targetSys, targetComp, count, MAV_MISSION_TYPE_MISSION, 0);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionItemInt(uint8_t targetSys, uint8_t targetComp,
                                        const mavlink_mission_item_int_t &item)
{
    mavlink_message_t msg;
    mavlink_msg_mission_item_int_pack(m_sysId, m_compId, &msg,
                                      targetSys, targetComp,
                                      item.seq, item.frame, item.command,
                                      item.current, item.autocontinue,
                                      item.param1, item.param2, item.param3, item.param4,
                                      item.x, item.y, item.z,
                                      item.mission_type);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionItem(uint8_t targetSys, uint8_t targetComp,
                                     const mavlink_mission_item_t &item)
{
    mavlink_message_t msg;
    mavlink_msg_mission_item_pack(m_sysId, m_compId, &msg,
                                  targetSys, targetComp,
                                  item.seq, item.frame, item.command,
                                  item.current, item.autocontinue,
                                  item.param1, item.param2, item.param3, item.param4,
                                  item.x, item.y, item.z, MAV_MISSION_TYPE_MISSION);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionRequestList(uint8_t targetSys, uint8_t targetComp)
{
    mavlink_message_t msg;
    mavlink_msg_mission_request_list_pack(m_sysId, m_compId, &msg,
                                          targetSys, targetComp, MAV_MISSION_TYPE_MISSION);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionRequestInt(uint8_t targetSys, uint8_t targetComp, uint16_t seq)
{
    mavlink_message_t msg;
    mavlink_msg_mission_request_int_pack(m_sysId, m_compId, &msg,
                                         targetSys, targetComp, seq, MAV_MISSION_TYPE_MISSION);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionRequest(uint8_t targetSys, uint8_t targetComp, uint16_t seq)
{
    mavlink_message_t msg;
    mavlink_msg_mission_request_pack(m_sysId, m_compId, &msg,
                                     targetSys, targetComp, seq, MAV_MISSION_TYPE_MISSION);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionAck(uint8_t targetSys, uint8_t targetComp, MAV_MISSION_RESULT result)
{
    mavlink_message_t msg;
    mavlink_msg_mission_ack_pack(m_sysId, m_compId, &msg,
                                 targetSys, targetComp, result, MAV_MISSION_TYPE_MISSION, 0);
    sendMessage(msg);
}

void MAVLinkSender::sendMissionClearAll(uint8_t targetSys, uint8_t targetComp)
{
    mavlink_message_t msg;
    mavlink_msg_mission_clear_all_pack(m_sysId, m_compId, &msg,
                                       targetSys, targetComp, MAV_MISSION_TYPE_MISSION);
    sendMessage(msg);
}

void MAVLinkSender::sendSetMode(uint8_t targetSys, uint8_t baseMode, uint32_t customMode)
{
    mavlink_message_t msg;
    mavlink_msg_set_mode_pack(m_sysId, m_compId, &msg, targetSys, baseMode, customMode);
    sendMessage(msg);
}

} // namespace IndigenousGCS
