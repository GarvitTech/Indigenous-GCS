#include "LogReader.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariantMap>
#include <QStandardPaths>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcLogReader, "igcs.logreader")

namespace IndigenousGCS {

LogReader::LogReader(QObject *parent) : QObject(parent)
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                         + "/flightlogs.db";
    m_db = QSqlDatabase::addDatabase("QSQLITE", "logreader");
    m_db.setDatabaseName(path);
    if (!m_db.open())
        qCWarning(lcLogReader) << "Cannot open log DB:" << m_db.lastError().text();
}

QVariantList LogReader::listSessions() const
{
    QVariantList result;
    QSqlQuery q("SELECT id, label, started, stopped FROM sessions ORDER BY id DESC", m_db);
    while (q.next()) {
        QVariantMap m;
        m["id"]      = q.value(0).toLongLong();
        m["label"]   = q.value(1).toString();
        m["started"] = q.value(2).toString();
        m["stopped"] = q.value(3).toString();
        result.append(m);
    }
    return result;
}

QVariantList LogReader::readSession(qint64 sessionId) const
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT ts,lat,lon,alt_rel,roll,pitch,yaw,"
              "ground_spd,climb_rate,batt_v,batt_pct,"
              "gps_fix,gps_sats,flight_mode,armed "
              "FROM telemetry WHERE session_id=? ORDER BY id");
    q.addBindValue(sessionId);
    if (!q.exec()) {
        qCWarning(lcLogReader) << q.lastError().text();
        return result;
    }
    while (q.next()) {
        QVariantMap m;
        m["ts"]          = q.value(0).toString();
        m["lat"]         = q.value(1).toDouble();
        m["lon"]         = q.value(2).toDouble();
        m["altRel"]      = q.value(3).toDouble();
        m["roll"]        = q.value(4).toDouble();
        m["pitch"]       = q.value(5).toDouble();
        m["yaw"]         = q.value(6).toDouble();
        m["groundSpeed"] = q.value(7).toDouble();
        m["climbRate"]   = q.value(8).toDouble();
        m["battVoltage"] = q.value(9).toDouble();
        m["battPct"]     = q.value(10).toInt();
        m["gpsFix"]      = q.value(11).toInt();
        m["gpsSats"]     = q.value(12).toInt();
        m["flightMode"]  = q.value(13).toString();
        m["armed"]       = q.value(14).toInt() != 0;
        result.append(m);
    }
    return result;
}

} // namespace IndigenousGCS
