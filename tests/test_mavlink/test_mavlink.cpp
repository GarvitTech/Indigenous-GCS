#include <QtTest>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

class TestMAVLink : public QObject
{
    Q_OBJECT

private slots:
    void testHeartbeatEncodeDecode() {
        mavlink_message_t msg;
        mavlink_msg_heartbeat_pack(255, 190, &msg,
                                   MAV_TYPE_QUADROTOR,
                                   MAV_AUTOPILOT_ARDUPILOTMEGA,
                                   MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                                   5, MAV_STATE_ACTIVE);
        QCOMPARE(msg.msgid, (uint32_t)MAVLINK_MSG_ID_HEARTBEAT);

        mavlink_heartbeat_t hb;
        mavlink_msg_heartbeat_decode(&msg, &hb);
        QCOMPARE(hb.type,        (uint8_t)MAV_TYPE_QUADROTOR);
        QCOMPARE(hb.autopilot,   (uint8_t)MAV_AUTOPILOT_ARDUPILOTMEGA);
        QCOMPARE(hb.custom_mode, (uint32_t)5);
    }

    void testHeartbeatSerialise() {
        mavlink_message_t msg;
        mavlink_msg_heartbeat_pack(1, 1, &msg,
                                   MAV_TYPE_QUADROTOR,
                                   MAV_AUTOPILOT_ARDUPILOTMEGA,
                                   MAV_MODE_FLAG_SAFETY_ARMED | MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                                   0, MAV_STATE_ACTIVE);

        uint8_t buf[MAVLINK_MAX_PACKET_LEN];
        uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
        QVERIFY(len > 0);
        QVERIFY(len <= MAVLINK_MAX_PACKET_LEN);
    }

    void testParseRoundTrip() {
        mavlink_message_t txMsg;
        mavlink_msg_heartbeat_pack(1, 1, &txMsg,
                                   MAV_TYPE_QUADROTOR,
                                   MAV_AUTOPILOT_ARDUPILOTMEGA,
                                   0, 0, MAV_STATE_STANDBY);

        uint8_t buf[MAVLINK_MAX_PACKET_LEN];
        uint16_t len = mavlink_msg_to_send_buffer(buf, &txMsg);

        mavlink_message_t rxMsg;
        mavlink_status_t  status;
        memset(&rxMsg, 0, sizeof(rxMsg));
        memset(&status, 0, sizeof(status));

        bool parsed = false;
        for (uint16_t i = 0; i < len; ++i) {
            if (mavlink_parse_char(MAVLINK_COMM_0, buf[i], &rxMsg, &status)) {
                parsed = true;
                break;
            }
        }
        QVERIFY(parsed);
        QCOMPARE(rxMsg.msgid, (uint32_t)MAVLINK_MSG_ID_HEARTBEAT);
        QCOMPARE(rxMsg.sysid,  (uint8_t)1);
        QCOMPARE(rxMsg.compid, (uint8_t)1);
    }

    void testArmedFlag() {
        uint8_t baseMode = MAV_MODE_FLAG_SAFETY_ARMED | MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
        QVERIFY(baseMode & MAV_MODE_FLAG_SAFETY_ARMED);
    }

    void testCommandLongEncode() {
        mavlink_message_t msg;
        mavlink_msg_command_long_pack(255, 190, &msg,
                                      1, 1,
                                      MAV_CMD_COMPONENT_ARM_DISARM,
                                      0,
                                      1.0f, 0.0f, 0, 0, 0, 0, 0);
        QCOMPARE(msg.msgid, (uint32_t)MAVLINK_MSG_ID_COMMAND_LONG);

        mavlink_command_long_t cmd;
        mavlink_msg_command_long_decode(&msg, &cmd);
        QCOMPARE(cmd.command, (uint16_t)MAV_CMD_COMPONENT_ARM_DISARM);
        QCOMPARE(cmd.param1,  1.0f);
    }
};

QTEST_MAIN(TestMAVLink)
#include "test_mavlink.moc"
