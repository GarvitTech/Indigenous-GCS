# MAVLink Implementation

## Dialect
Standard MAVLink 2 common dialect. No custom messages required for basic operation.

## Messages Implemented

| ID  | Name                  | Direction | Rate      |
|-----|-----------------------|-----------|-----------|
| 0   | HEARTBEAT             | Both      | 1 Hz      |
| 1   | SYS_STATUS            | FC→GCS    | 1 Hz      |
| 24  | GPS_RAW_INT           | FC→GCS    | 5 Hz      |
| 30  | ATTITUDE              | FC→GCS    | 10 Hz     |
| 33  | GLOBAL_POSITION_INT   | FC→GCS    | 5 Hz      |
| 74  | VFR_HUD               | FC→GCS    | 5 Hz      |
| 76  | COMMAND_LONG          | GCS→FC    | on demand |
| 77  | COMMAND_ACK           | FC→GCS    | on demand |
| 147 | BATTERY_STATUS        | FC→GCS    | 1 Hz      |
| 253 | STATUSTEXT            | FC→GCS    | as needed |
| 20  | PARAM_REQUEST_LIST    | GCS→FC    | on demand |
| 21  | PARAM_REQUEST_READ    | GCS→FC    | on demand |
| 22  | PARAM_VALUE           | FC→GCS    | on demand |
| 23  | PARAM_SET             | GCS→FC    | on demand |
| 43  | MISSION_ITEM          | Both      | protocol  |
| 44  | MISSION_REQUEST       | GCS→FC    | protocol  |
| 45  | MISSION_COUNT         | Both      | protocol  |
| 47  | MISSION_ITEM_INT      | Both      | protocol  |
| 51  | MISSION_REQUEST_INT   | GCS→FC    | protocol  |
| 47  | MISSION_ACK           | Both      | protocol  |
| 48  | MISSION_CLEAR_ALL     | GCS→FC    | on demand |
| 242 | HOME_POSITION         | FC→GCS    | on demand |

## GCS Identity
- System ID:    255 (configurable in AppSettings)
- Component ID: 190 (MAV_COMP_ID_MISSIONPLANNER)

## Heartbeat Timeout
5000 ms — vehicle marked LOST if no heartbeat received within this window.

## ARM/DISARM Command
```
MAV_CMD_COMPONENT_ARM_DISARM (400)
  param1 = 1.0  → ARM
  param1 = 0.0  → DISARM
  param2 = 21196.0 → force (bypass safety checks)
```

## Flight Mode Change
```
SET_MODE (message ID 11)
  target_system = vehicle sysId
  base_mode     = MAV_MODE_FLAG_CUSTOM_MODE_ENABLED | armed_flag
  custom_mode   = ArduCopter mode number
```

## Custom Mode Numbers (ArduCopter / ESP32 FC)
| Number | Name       |
|--------|------------|
| 0      | Stabilize  |
| 2      | Alt Hold   |
| 3      | Auto       |
| 4      | Guided     |
| 5      | Loiter     |
| 6      | RTL        |
| 9      | Land       |
| 16     | PosHold    |
| 17     | Brake      |
