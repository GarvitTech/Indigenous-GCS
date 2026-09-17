#pragma once
#include <QObject>
#include <QString>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

namespace IndigenousGCS {

class Waypoint
{
public:
    uint16_t seq          = 0;
    uint16_t command      = MAV_CMD_NAV_WAYPOINT;
    uint8_t  frame        = MAV_FRAME_GLOBAL_RELATIVE_ALT;
    bool     autoContinue = true;
    bool     current      = false;

    double   latitude     = 0.0;
    double   longitude    = 0.0;
    float    altitude     = 10.0f;

    float    param1       = 0.0f;  // hold time (s)
    float    param2       = 2.0f;  // acceptance radius (m)
    float    param3       = 0.0f;  // pass-through radius
    float    param4       = 0.0f;  // yaw

    QString commandName() const;

    mavlink_mission_item_int_t toMavlinkItem() const;
    static Waypoint fromMavlinkItem(const mavlink_mission_item_int_t &item);
};

} // namespace IndigenousGCS
