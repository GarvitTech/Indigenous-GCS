#include "Waypoint.h"
#include <QHash>

namespace IndigenousGCS {

QString Waypoint::commandName() const
{
    static const QHash<uint16_t, QString> names = {
        {MAV_CMD_NAV_WAYPOINT,        "Waypoint"},
        {MAV_CMD_NAV_TAKEOFF,         "Takeoff"},
        {MAV_CMD_NAV_LAND,            "Land"},
        {MAV_CMD_NAV_RETURN_TO_LAUNCH,"RTL"},
        {MAV_CMD_NAV_LOITER_UNLIM,    "Loiter"},
        {MAV_CMD_NAV_LOITER_TIME,     "Loiter Time"},
        {MAV_CMD_NAV_LOITER_TURNS,    "Loiter Turns"},
    };
    return names.value(command, QString("CMD %1").arg(command));
}

mavlink_mission_item_int_t Waypoint::toMavlinkItem() const
{
    mavlink_mission_item_int_t item{};
    item.seq          = seq;
    item.command      = command;
    item.frame        = frame;
    item.autocontinue = autoContinue ? 1 : 0;
    item.current      = current ? 1 : 0;
    item.x            = static_cast<int32_t>(latitude  * 1e7);
    item.y            = static_cast<int32_t>(longitude * 1e7);
    item.z            = altitude;
    item.param1       = param1;
    item.param2       = param2;
    item.param3       = param3;
    item.param4       = param4;
    item.mission_type = MAV_MISSION_TYPE_MISSION;
    return item;
}

Waypoint Waypoint::fromMavlinkItem(const mavlink_mission_item_int_t &item)
{
    Waypoint wp;
    wp.seq          = item.seq;
    wp.command      = item.command;
    wp.frame        = item.frame;
    wp.autoContinue = item.autocontinue != 0;
    wp.current      = item.current != 0;
    wp.latitude     = item.x / 1e7;
    wp.longitude    = item.y / 1e7;
    wp.altitude     = item.z;
    wp.param1       = item.param1;
    wp.param2       = item.param2;
    wp.param3       = item.param3;
    wp.param4       = item.param4;
    return wp;
}

} // namespace IndigenousGCS
