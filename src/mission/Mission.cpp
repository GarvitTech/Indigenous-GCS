#include "Mission.h"
#include <QVariantMap>
#include <cmath>

namespace IndigenousGCS {

Mission::Mission(QObject *parent) : QObject(parent) {}

QVariantList Mission::waypointList() const
{
    QVariantList result;
    result.reserve(m_waypoints.size());
    for (const Waypoint &waypoint : m_waypoints) {
        QVariantMap item;
        item.insert("seq", waypoint.seq);
        item.insert("command", waypoint.command);
        item.insert("commandName", waypoint.commandName());
        item.insert("latitude", waypoint.latitude);
        item.insert("longitude", waypoint.longitude);
        item.insert("altitude", waypoint.altitude);
        result.append(item);
    }
    return result;
}

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
        if (!std::isfinite(wp.latitude) || wp.latitude < -90.0 || wp.latitude > 90.0)
            errors << QString("Waypoint %1 has invalid latitude").arg(i);
        if (!std::isfinite(wp.longitude) || wp.longitude < -180.0 || wp.longitude > 180.0)
            errors << QString("Waypoint %1 has invalid longitude").arg(i);
        if (!std::isfinite(wp.altitude) || wp.altitude < -100.0f || wp.altitude > 10000.0f)
            errors << QString("Waypoint %1 has invalid altitude %2").arg(i).arg(wp.altitude);
    }
    return errors;
}

} // namespace IndigenousGCS
