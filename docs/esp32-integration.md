# ESP32 Flight Controller — MAVLink Integration Guide

This document defines exactly what the ESP32 firmware must implement for full GCS compatibility.

---

## Required MAVLink Messages (FC → GCS)

### HEARTBEAT (ID 0) — 1 Hz minimum
```c
mavlink_msg_heartbeat_send(chan,
    MAV_TYPE_QUADROTOR,
    MAV_AUTOPILOT_ARDUPILOTMEGA,  // or MAV_AUTOPILOT_GENERIC
    base_mode,    // MAV_MODE_FLAG_CUSTOM_MODE_ENABLED | armed flag
    custom_mode,  // 0=Stabilize, 2=AltHold, 5=Loiter, 6=RTL, 9=Land
    system_status // MAV_STATE_STANDBY or MAV_STATE_ACTIVE
);
```

### SYS_STATUS (ID 1) — 1 Hz
```c
mavlink_msg_sys_status_send(chan,
    sensors_present,  // MAV_SYS_STATUS_SENSOR bitmask
    sensors_enabled,
    sensors_health,
    cpu_load,         // per mille (0-1000)
    voltage_battery,  // millivolts
    current_battery,  // centiamperes (-1 if unknown)
    battery_remaining // percent (-1 if unknown)
    ...
);
```

### ATTITUDE (ID 30) — 10 Hz minimum
```c
mavlink_msg_attitude_send(chan,
    time_boot_ms,
    roll, pitch, yaw,           // radians
    rollspeed, pitchspeed, yawspeed  // rad/s
);
```

### GLOBAL_POSITION_INT (ID 33) — 5 Hz minimum
```c
mavlink_msg_global_position_int_send(chan,
    time_boot_ms,
    lat * 1e7,   // degrees * 1e7
    lon * 1e7,
    alt * 1000,  // mm above MSL
    relative_alt * 1000,  // mm above home
    vx, vy, vz,  // cm/s
    hdg * 100    // degrees * 100
);
```

### GPS_RAW_INT (ID 24) — 5 Hz
```c
mavlink_msg_gps_raw_int_send(chan,
    time_usec,
    fix_type,    // GPS_FIX_TYPE enum
    lat * 1e7, lon * 1e7, alt * 1000,
    eph, epv,    // cm
    vel,         // cm/s
    cog,         // degrees * 100
    satellites_visible
);
```

### VFR_HUD (ID 74) — 5 Hz
```c
mavlink_msg_vfr_hud_send(chan,
    airspeed, groundspeed,  // m/s
    heading,                // degrees
    throttle,               // 0-100%
    alt,                    // m MSL
    climb                   // m/s
);
```

### BATTERY_STATUS (ID 147) — 1 Hz
```c
mavlink_msg_battery_status_send(chan,
    id, battery_function, type,
    temperature,
    voltages,        // uint16[10] millivolts per cell
    current_battery, // centiamperes
    current_consumed,
    energy_consumed,
    battery_remaining // percent
    ...
);
```

### STATUSTEXT (ID 253) — as needed
```c
mavlink_msg_statustext_send(chan, severity, text);
// severity: MAV_SEVERITY_INFO, WARNING, CRITICAL, etc.
```

---

## Required MAVLink Commands (GCS → FC)

### MAV_CMD_COMPONENT_ARM_DISARM (400)
- param1 = 1.0 → ARM
- param1 = 0.0 → DISARM
- param2 = 21196.0 → force (bypass safety)
- **Must respond with COMMAND_ACK**

### MAV_CMD_DO_SET_MODE / SET_MODE (ID 11)
- base_mode: MAV_MODE_FLAG bitmask
- custom_mode: flight mode number
- **Must respond with COMMAND_ACK**

### MAV_CMD_PREFLIGHT_CALIBRATION (241)
- param1=1 → gyro calibration
- param2=1 → magnetometer calibration
- param5=1 → accelerometer calibration
- param5=2 → level calibration
- **Must send STATUSTEXT progress messages**
- **Must respond with COMMAND_ACK**

### MAV_CMD_REQUEST_AUTOPILOT_CAPABILITIES (520)
- Respond with AUTOPILOT_VERSION message

---

## Parameter Protocol

The FC must implement:
- **PARAM_REQUEST_LIST** → respond with all PARAM_VALUE messages
- **PARAM_REQUEST_READ** → respond with single PARAM_VALUE
- **PARAM_SET** → set parameter, respond with PARAM_VALUE

Each PARAM_VALUE must include:
- param_id (16 char null-terminated)
- param_value (float)
- param_type (MAV_PARAM_TYPE)
- param_index
- param_count

---

## Mission Protocol

The FC must implement the MAVLink mission protocol:
1. GCS sends MISSION_COUNT
2. FC requests each item with MISSION_REQUEST_INT
3. GCS sends MISSION_ITEM_INT for each
4. FC sends MISSION_ACK when complete

For download:
1. GCS sends MISSION_REQUEST_LIST
2. FC responds with MISSION_COUNT
3. GCS requests each item with MISSION_REQUEST_INT
4. FC sends MISSION_ITEM_INT for each
5. GCS sends MISSION_ACK

---

## Recommended ESP32 Libraries

- **MAVLink C library**: https://github.com/mavlink/c_library_v2
- **Arduino MAVLink**: include mavlink.h, use Serial.write() for sending

## Minimal Arduino Example

```cpp
#include "mavlink/common/mavlink.h"

void sendHeartbeat() {
    mavlink_message_t msg;
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    mavlink_msg_heartbeat_pack(1, 1, &msg,
        MAV_TYPE_QUADROTOR, MAV_AUTOPILOT_GENERIC,
        MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, 0, MAV_STATE_STANDBY);
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    Serial.write(buf, len);
}

void loop() {
    static uint32_t lastHB = 0;
    if (millis() - lastHB > 1000) { sendHeartbeat(); lastHB = millis(); }
    // Parse incoming bytes
    while (Serial.available()) {
        mavlink_message_t msg;
        mavlink_status_t status;
        if (mavlink_parse_char(MAVLINK_COMM_0, Serial.read(), &msg, &status))
            handleMessage(msg);
    }
}
```
