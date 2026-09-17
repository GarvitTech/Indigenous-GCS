#pragma once
#include <QObject>
#include <QByteArray>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

namespace IndigenousGCS {

class MAVLinkSender : public QObject
{
    Q_OBJECT
public:
    explicit MAVLinkSender(QObject *parent = nullptr);

    void setSystemId(uint8_t sysId)   { m_sysId  = sysId; }
    void setComponentId(uint8_t compId) { m_compId = compId; }

    void sendHeartbeat();
    void sendCommandLong(uint8_t targetSys, uint8_t targetComp,
                         uint16_t command,
                         float p1=0, float p2=0, float p3=0,
                         float p4=0, float p5=0, float p6=0, float p7=0,
                         uint8_t confirmation=0);
    void sendParamRequestList(uint8_t targetSys, uint8_t targetComp);
    void sendParamRequestRead(uint8_t targetSys, uint8_t targetComp,
                              const QString &paramId, int16_t paramIndex = -1);
    void sendParamSet(uint8_t targetSys, uint8_t targetComp,
                      const QString &paramId, float value,
                      MAV_PARAM_TYPE type = MAV_PARAM_TYPE_REAL32);
    void sendMissionCount(uint8_t targetSys, uint8_t targetComp, uint16_t count);
    void sendMissionItemInt(uint8_t targetSys, uint8_t targetComp,
                            const mavlink_mission_item_int_t &item);
    void sendMissionRequestList(uint8_t targetSys, uint8_t targetComp);
    void sendMissionRequestInt(uint8_t targetSys, uint8_t targetComp, uint16_t seq);
    void sendMissionAck(uint8_t targetSys, uint8_t targetComp, MAV_MISSION_RESULT result);
    void sendMissionClearAll(uint8_t targetSys, uint8_t targetComp);
    void sendSetMode(uint8_t targetSys, uint8_t baseMode, uint32_t customMode);

signals:
    void bytesToSend(const QByteArray &data);

private:
    void sendMessage(mavlink_message_t &msg);

    uint8_t m_sysId  = 255;
    uint8_t m_compId = 190;
};

} // namespace IndigenousGCS
