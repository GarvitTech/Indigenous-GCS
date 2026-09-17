#pragma once
#include <QObject>
#include <QList>
#include <QString>
#include "Waypoint.h"

namespace IndigenousGCS {

class Mission : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int     count    READ count    NOTIFY waypointsChanged)
    Q_PROPERTY(bool    modified READ modified NOTIFY modifiedChanged)
    Q_PROPERTY(QString name     READ name     WRITE setName NOTIFY nameChanged)

public:
    explicit Mission(QObject *parent = nullptr);

    int     count()    const { return m_waypoints.size(); }
    bool    modified() const { return m_modified; }
    QString name()     const { return m_name; }

    const QList<Waypoint> &waypoints() const { return m_waypoints; }

    Q_INVOKABLE void addWaypoint(double lat, double lon, float alt,
                                 uint16_t command = MAV_CMD_NAV_WAYPOINT);
    Q_INVOKABLE void removeWaypoint(int index);
    Q_INVOKABLE void moveWaypoint(int from, int to);
    Q_INVOKABLE void clear();

    void setWaypoints(const QList<Waypoint> &wps);
    void setName(const QString &name);
    void setModified(bool m);

    // Validation — returns list of error strings (empty = valid)
    QStringList validate() const;

signals:
    void waypointsChanged();
    void modifiedChanged();
    void nameChanged();

private:
    void renumber();

    QList<Waypoint> m_waypoints;
    QString         m_name     = "New Mission";
    bool            m_modified = false;
};

} // namespace IndigenousGCS
