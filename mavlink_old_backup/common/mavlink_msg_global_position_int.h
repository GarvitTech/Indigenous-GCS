#pragma once
// GLOBAL_POSITION_INT (ID 33)
// Fused global position estimate.

#define MAVLINK_MSG_ID_GLOBAL_POSITION_INT 33

typedef struct __mavlink_global_position_int_t {
    uint32_t time_boot_ms;   // ms since boot
    int32_t  lat;            // deg * 1e7
    int32_t  lon;            // deg * 1e7
    int32_t  alt;            // mm above MSL
    int32_t  relative_alt;  // mm above home
    int16_t  vx;             // cm/s north
    int16_t  vy;             // cm/s east
    int16_t  vz;             // cm/s down
    uint16_t hdg;            // heading cdeg (0-35999), UINT16_MAX unknown
} mavlink_global_position_int_t;

#define MAVLINK_MSG_ID_GLOBAL_POSITION_INT_LEN 28
#define MAVLINK_MSG_ID_GLOBAL_POSITION_INT_CRC 104

static inline uint16_t mavlink_msg_global_position_int_pack(
    uint8_t system_id, uint8_t component_id, mavlink_message_t *msg,
    uint32_t time_boot_ms, int32_t lat, int32_t lon,
    int32_t alt, int32_t relative_alt,
    int16_t vx, int16_t vy, int16_t vz, uint16_t hdg)
{
    mavlink_global_position_int_t packet;
    packet.time_boot_ms = time_boot_ms;
    packet.lat          = lat;
    packet.lon          = lon;
    packet.alt          = alt;
    packet.relative_alt = relative_alt;
    packet.vx           = vx;
    packet.vy           = vy;
    packet.vz           = vz;
    packet.hdg          = hdg;

    memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet,
           MAVLINK_MSG_ID_GLOBAL_POSITION_INT_LEN);
    msg->msgid = MAVLINK_MSG_ID_GLOBAL_POSITION_INT;
    return mavlink_finalize_message(msg, system_id, component_id,
                                    MAVLINK_MSG_ID_GLOBAL_POSITION_INT_LEN,
                                    MAVLINK_MSG_ID_GLOBAL_POSITION_INT_CRC);
}

static inline void mavlink_msg_global_position_int_decode(
    const mavlink_message_t *msg, mavlink_global_position_int_t *global_position_int)
{
    memcpy(global_position_int, _MAV_PAYLOAD(msg),
           MAVLINK_MSG_ID_GLOBAL_POSITION_INT_LEN);
}

#define MAVLINK_MSG_ID_33_LEN   MAVLINK_MSG_ID_GLOBAL_POSITION_INT_LEN
#define MAVLINK_MSG_ID_33_CRC   MAVLINK_MSG_ID_GLOBAL_POSITION_INT_CRC
