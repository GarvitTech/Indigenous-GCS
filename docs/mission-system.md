# Mission System

## Overview
The mission system implements the full MAVLink mission protocol for uploading and downloading waypoint missions to/from the flight controller.

## Upload Protocol
```
GCS                          FC
 |                            |
 |--- MISSION_COUNT(n) ------>|
 |<-- MISSION_REQUEST_INT(0) -|
 |--- MISSION_ITEM_INT(0) --->|
 |<-- MISSION_REQUEST_INT(1) -|
 |--- MISSION_ITEM_INT(1) --->|
 |         ...                |
 |--- MISSION_ITEM_INT(n-1) ->|
 |<-- MISSION_ACK(ACCEPTED) --|
```

## Download Protocol
```
GCS                          FC
 |                            |
 |--- MISSION_REQUEST_LIST -->|
 |<-- MISSION_COUNT(n) -------|
 |--- MISSION_REQUEST_INT(0)->|
 |<-- MISSION_ITEM_INT(0) ----|
 |--- MISSION_REQUEST_INT(1)->|
 |<-- MISSION_ITEM_INT(1) ----|
 |         ...                |
 |--- MISSION_ACK(ACCEPTED) ->|
```

## Timeout
5000 ms per message exchange. Transfer fails if no response received.

## Supported Commands
| MAV_CMD                  | Description        |
|--------------------------|--------------------|
| MAV_CMD_NAV_WAYPOINT     | Navigate to point  |
| MAV_CMD_NAV_TAKEOFF      | Takeoff            |
| MAV_CMD_NAV_LAND         | Land               |
| MAV_CMD_NAV_RETURN_TO_LAUNCH | RTL            |
| MAV_CMD_NAV_LOITER_UNLIM | Loiter unlimited   |
| MAV_CMD_NAV_LOITER_TIME  | Loiter for time    |
| MAV_CMD_NAV_LOITER_TURNS | Loiter N turns     |

## Coordinate Frame
All waypoints use MAV_FRAME_GLOBAL_RELATIVE_ALT (altitude relative to home).

## File Format
Missions are saved as JSON:
```json
{
  "version": 1,
  "name": "My Mission",
  "waypoints": [
    {
      "seq": 0,
      "command": 22,
      "frame": 3,
      "autoContinue": true,
      "latitude": 28.6139,
      "longitude": 77.2090,
      "altitude": 10.0,
      "param1": 0, "param2": 2, "param3": 0, "param4": 0
    }
  ]
}
```

## Validation Rules
- Mission must not be empty
- Coordinates must not be (0,0) for nav waypoints
- Altitude must be between -100 and 10000 m
