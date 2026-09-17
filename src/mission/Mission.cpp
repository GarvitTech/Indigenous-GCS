#include "Mission.h"

namespace IndigenousGCS {

Mission::Mission(QObject *parent) : QObject(parent) {}

void Mission::addWaypoint(double lat, double lon, float alt, uint16_t command)
{
    Waypoint wp;
    wp.seq       = static_cast<uint16_t>(m_waypoints.size());
    wp.command   = command;
    wp.latitude  = lat;
    wp.longitude = lon;
    wp.altitude  = alt;
    m_waypoints.append(wp);
    setModified(true);
    emit waypointsChanged();
}

void Mission::removeWaypoint(int index)
{
    if (index < 0 || index >= m_waypoints.size()) return;
    m_waypoints.removeAt(index);
    renumber();
    setModified(true);
    emit waypointsChanged();
}

void Mission::moveWaypoint(int from, int to)
{
    if (from < 0 || from >= m_waypoints.size()) return;
    if (to   < 0 || to   >= m_waypoints.size()) return;
    m_waypoints.move(from, to);
    renumber();
    setModified(true);
    emit waypointsChanged();
}

void Mission::clear()
{
    m_waypoints.clear();
    setModified(true);
    emit waypointsChanged();
}

void Mission::setWaypoints(const QList<Waypoint> &wps)
{
    m_waypoints = wps;
    renumber();
    setModified(false);
    emit waypointsChanged();
}

void Mission::setName(const QString &name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
}

void Mission::setModified(bool m)
{
    if (m_modified == m) return;
    m_modified = m;
    emit modifiedChanged();
}

void Mission::renumber()
{
    for (int i = 0; i < m_waypoints.size(); ++i)
        m_waypoints[i].seq = static_cast<uint16_t>(i);
}

QStringList Mission::validate() const
{
    QStringList errors;
    if (m_waypoints.isEmpty()) {
        errors << "Mission is empty";
        return errors;
    }
    for (int i = 0; i < m_waypoints.size(); ++i) {
        const Waypoint &wp = m_waypoints[i];
        if (wp.latitude  == 0.0 && wp.longitude == 0.0 &&
            wp.command != MAV_CMD_NAV_TAKEOFF &&
            wp.command != MAV_CMD_NAV_RETURN_TO_LAUNCH)
            errors << QString("Waypoint %1 has zero coordinates").arg(i);
        if (wp.altitude < -100.0f || wp.altitude > 10000.0f)
            errors << QString("Waypoint %1 has invalid altitude %2").arg(i).arg(wp.altitude);
    }
    return errors;
}

} // namespace IndigenousGCS
