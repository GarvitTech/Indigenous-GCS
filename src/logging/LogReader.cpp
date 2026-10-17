#include "LogReader.h"
#include "LogPaths.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariantMap>
#include <QStandardPaths>
#include <QDateTime>
#include <QFile>
#include <QTextStream>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcLogReader, "igcs.logreader")

namespace IndigenousGCS {

LogReader::LogReader(QObject *parent) : QObject(parent)
{
    // Must resolve to exactly the same file FlightLogger writes. These two
    // classes previously built independent paths ("flightlogs.db" here,
    // "logs.db" there), so every recording was written to one database and
    // read from an empty other one — logging appeared to do nothing at all.
    const QString path = LogPaths::databasePath();
    if (path.isEmpty()) {
        qCWarning(lcLogReader) << "Cannot locate the log database directory";
        return;
    }

    if (QSqlDatabase::contains(QStringLiteral("logreader")))
        m_db = QSqlDatabase::database(QStringLiteral("logreader"));
    else
        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"),
                                         QStringLiteral("logreader"));

    m_db.setDatabaseName(path);
    if (!m_db.open()) {
        qCWarning(lcLogReader) << "Cannot open log DB:" << path << m_db.lastError().text();
        return;
    }

    QSqlQuery pragma(m_db);
    pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    qCInfo(lcLogReader) << "Log reader ready:" << path;
}

QVariantList LogReader::listSessions() const
{
    QVariantList result;
    if (!m_db.isOpen()) {
        qCWarning(lcLogReader) << "Cannot list sessions: database is not open";
        return result;
    }

    // rowCount is computed per session so the Logs page can show how much data
    // each recording actually holds rather than just its timestamps.
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT s.id, s.label, s.started, s.stopped, "
        "       (SELECT COUNT(*) FROM telemetry t WHERE t.session_id = s.id) "
        "FROM sessions s ORDER BY s.id DESC"));
    if (!q.exec()) {
        qCWarning(lcLogReader) << "Cannot list sessions:" << q.lastError().text();
        return result;
    }

    while (q.next()) {
        QVariantMap m;
        m["id"]       = q.value(0).toLongLong();
        m["label"]    = q.value(1).toString();
        m["started"]  = q.value(2).toString();
        m["stopped"]  = q.value(3).toString();
        m["rowCount"] = q.value(4).toInt();

        // Duration in seconds, derived from the ISO timestamps. A session that
        // was never stopped reports -1 so the UI can say "in progress" instead
        // of showing a misleading zero.
        const QDateTime start = QDateTime::fromString(m["started"].toString(), Qt::ISODate);
        const QDateTime stop  = QDateTime::fromString(m["stopped"].toString(), Qt::ISODate);
        if (start.isValid() && stop.isValid())
            m["duration"] = static_cast<int>(start.secsTo(stop));
        else
            m["duration"] = -1;

        result.append(m);
    }
    return result;
}

QVariantList LogReader::readSession(qint64 sessionId) const
{
    QVariantList result;
    if (!m_db.isOpen())
        return result;

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

bool LogReader::clearSessions()
{
    if (!m_db.isOpen()) {
        qCWarning(lcLogReader) << "Cannot clear logs: database is not open";
        return false;
    }
    if (!m_db.transaction()) {
        qCWarning(lcLogReader) << "Cannot start log deletion transaction:" << m_db.lastError().text();
        return false;
    }

    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral("DELETE FROM telemetry")) ||
        !q.exec(QStringLiteral("DELETE FROM sessions"))) {
        qCWarning(lcLogReader) << "Cannot clear logs:" << q.lastError().text();
        m_db.rollback();
        return false;
    }
    if (!m_db.commit()) {
        qCWarning(lcLogReader) << "Cannot commit log deletion:" << m_db.lastError().text();
        m_db.rollback();
        return false;
    }
    qCInfo(lcLogReader) << "All flight logs cleared";
    return true;
}

QString LogReader::databasePath() const
{
    return m_db.isOpen() ? m_db.databaseName() : LogPaths::databasePath();
}

QString LogReader::suggestedExportName(qint64 sessionId) const
{
    QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd"));

    // Prefer the session's own start date so the filename matches the flight.
    if (m_db.isOpen()) {
        QSqlQuery q(m_db);
        q.prepare(QStringLiteral("SELECT started FROM sessions WHERE id=?"));
        q.addBindValue(sessionId);
        if (q.exec() && q.next()) {
            const QDateTime started = QDateTime::fromString(q.value(0).toString(), Qt::ISODate);
            if (started.isValid())
                stamp = started.toString(QStringLiteral("yyyy-MM-dd_HHmmss"));
        }
    }
    return QStringLiteral("IndigenousGCS-log-%1-%2.csv").arg(sessionId).arg(stamp);
}

bool LogReader::exportSession(qint64 sessionId, const QString &filePath) const
{
    if (filePath.isEmpty()) {
        qCWarning(lcLogReader) << "Export requested with an empty path";
        return false;
    }

    const QVariantList rows = readSession(sessionId);
    if (rows.isEmpty()) {
        qCWarning(lcLogReader) << "Session" << sessionId << "has no rows to export";
        return false;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        qCWarning(lcLogReader) << "Cannot open export file:" << filePath << file.errorString();
        return false;
    }

    QTextStream out(&file);
    out << "# Indigenous GCS flight log export\n";
    out << "# session_id=" << sessionId << "\n";
    out << "# rows=" << rows.size() << "\n";
    out << "timestamp,latitude,longitude,alt_rel_m,roll_deg,pitch_deg,yaw_deg,"
           "ground_speed_ms,climb_rate_ms,battery_v,battery_pct,gps_fix,gps_sats,"
           "flight_mode,armed\n";

    for (const QVariant &v : rows) {
        const QVariantMap m = v.toMap();
        out << m["ts"].toString()                          << ','
            << QString::number(m["lat"].toDouble(), 'f', 7) << ','
            << QString::number(m["lon"].toDouble(), 'f', 7) << ','
            << QString::number(m["altRel"].toDouble(), 'f', 2) << ','
            << QString::number(m["roll"].toDouble(), 'f', 2)   << ','
            << QString::number(m["pitch"].toDouble(), 'f', 2)  << ','
            << QString::number(m["yaw"].toDouble(), 'f', 2)    << ','
            << QString::number(m["groundSpeed"].toDouble(), 'f', 2) << ','
            << QString::number(m["climbRate"].toDouble(), 'f', 2)   << ','
            << QString::number(m["battVoltage"].toDouble(), 'f', 2) << ','
            << m["battPct"].toInt()      << ','
            << m["gpsFix"].toInt()       << ','
            << m["gpsSats"].toInt()      << ','
            << m["flightMode"].toString() << ','
            << (m["armed"].toBool() ? 1 : 0) << '\n';
    }

    out.flush();
    file.close();
    qCInfo(lcLogReader) << "Exported session" << sessionId << "to" << filePath;
    return true;
}

} // namespace IndigenousGCS
