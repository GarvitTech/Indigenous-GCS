#include "FlightLogger.h"
#include "LogPaths.h"
#include "vehicle/VehicleManager.h"
#include "vehicle/Vehicle.h"
#include "vehicle/Telemetry.h"
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QDir>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcLog, "igcs.logger")

namespace IndigenousGCS {

FlightLogger::FlightLogger(QObject *parent) : QObject(parent)
{
    // One canonical database shared with LogReader. If this diverges, the
    // recordings exist but the Logs page cannot see them.
    m_dbPath = LogPaths::databasePath();
    if (m_dbPath.isEmpty() || !openDatabase(m_dbPath))
        qCWarning(lcLog) << "Flight logging is unavailable: no writable log database";

    // Write timer fires every 1 second when logging
    m_writeTimer.setInterval(kWriteIntervalMs);
    connect(&m_writeTimer, &QTimer::timeout, this, &FlightLogger::onWriteTimer);
}

FlightLogger::~FlightLogger()
{
    stopLogging();
    if (m_db.isOpen()) m_db.close();
}

bool FlightLogger::openDatabase(const QString &path)
{
    // A previous failed attempt can leave the named connection registered, and
    // QSqlDatabase refuses to add a duplicate name. Reuse it in that case.
    if (QSqlDatabase::contains(QStringLiteral("flightlogger")))
        m_db = QSqlDatabase::database(QStringLiteral("flightlogger"));
    else
        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"),
                                         QStringLiteral("flightlogger"));

    m_db.setDatabaseName(path);
    if (!m_db.open()) {
        qCWarning(lcLog) << "Cannot open log DB:" << path << m_db.lastError().text();
        return false;
    }

    // WAL keeps a 1 Hz writer from blocking the reader in LogReader, and
    // survives an unclean shutdown far better than the default journal.
    QSqlQuery pragma(m_db);
    pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));

    createSchema();
    qCInfo(lcLog) << "Log database ready:" << path;
    return true;
}

void FlightLogger::createSchema()
{
    QSqlQuery q(m_db);

    q.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS sessions ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  vehicle_id TEXT,"
        "  label      TEXT,"
        "  started    TEXT,"
        "  stopped    TEXT"
        ")"));

    q.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS telemetry ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  session_id  INTEGER,"
        "  ts          TEXT,"
        "  lat         REAL, lon REAL, alt_rel REAL,"
        "  roll        REAL, pitch REAL, yaw REAL,"
        "  ground_spd  REAL, climb_rate REAL,"
        "  batt_v      REAL, batt_pct INTEGER,"
        "  gps_fix     INTEGER, gps_sats INTEGER,"
        "  flight_mode TEXT, armed INTEGER"
        ")"));

    q.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_tel_session ON telemetry(session_id)"));

    // ── Schema migration ─────────────────────────────────────────────────
    // An earlier build created a `sessions` table without the vehicle_id
    // column, and a second class created a *different* database with a
    // different schema. Rather than failing on those files, add the missing
    // column in place so previously recorded sessions remain readable.
    QSqlQuery check(m_db);
    check.exec(QStringLiteral("PRAGMA table_info(sessions)"));
    bool hasVehicleId = false;
    while (check.next()) {
        if (check.value(1).toString() == QLatin1String("vehicle_id"))
            hasVehicleId = true;
    }
    if (!hasVehicleId) {
        if (q.exec(QStringLiteral("ALTER TABLE sessions ADD COLUMN vehicle_id TEXT")))
            qCInfo(lcLog) << "Migrated sessions table: added vehicle_id column";
        else
            qCWarning(lcLog) << "Could not add vehicle_id column:" << q.lastError().text();
    }
}

// ── New API ──────────────────────────────────────────────────────────────────

void FlightLogger::startLogging(const QString &vehicleId)
{
    if (m_logging) return;

    // Surface the reason instead of silently doing nothing, which previously
    // left the RECORDING indicator on with nothing being written.
    if (!m_db.isOpen()) {
        qCWarning(lcLog) << "Cannot start logging: the log database is not open";
        emit loggingFailed(tr("Cannot start logging — the log database could not be opened."));
        return;
    }

    m_vehicleId = vehicleId.isEmpty() ? QStringLiteral("unknown") : vehicleId;
    m_startTime = QDateTime::currentDateTimeUtc();

    // Column order is (vehicle_id, label, started). The label is a
    // human-readable display name; `started` must be an ISODate string because
    // that is what getRecentLogs() and LogReader parse it back with. Writing a
    // 'yyyy-MM-dd HH:mm:ss' value here made every duration read as zero.
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO sessions(vehicle_id, label, started) VALUES(?,?,?)"));
    q.addBindValue(m_vehicleId);
    q.addBindValue(m_vehicleId);
    q.addBindValue(m_startTime.toString(Qt::ISODate));
    if (!q.exec()) {
        qCWarning(lcLog) << "Failed to create session:" << q.lastError().text();
        emit loggingFailed(tr("Cannot start logging — %1").arg(q.lastError().text()));
        return;
    }
    m_sessionId = q.lastInsertId().toLongLong();
    m_logging   = true;
    m_writeTimer.start();
    emit isLoggingChanged();
    emit loggingChanged();
    emit loggingStarted();
    qCInfo(lcLog) << "Logging started, session=" << m_sessionId << "vehicle=" << m_vehicleId;
}

void FlightLogger::stopLogging()
{
    if (!m_logging) return;
    m_writeTimer.stop();

    // Flush everything buffered before closing the session, otherwise the last
    // second of flight is lost.
    flushPending();

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE sessions SET stopped=? WHERE id=?"));
    q.addBindValue(QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    q.addBindValue(m_sessionId);
    q.exec();

    const int written = m_rowsWritten;
    m_logging   = false;
    m_sessionId = -1;
    m_pending.clear();
    m_rowsWritten = 0;
    emit isLoggingChanged();
    emit loggingChanged();
    emit loggingStopped();
    qCInfo(lcLog) << "Logging stopped," << written << "rows written";
}

int FlightLogger::currentSessionRowCount() const
{
    return m_rowsWritten;
}

QVariantList FlightLogger::getRecentLogs() const
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.exec("SELECT s.id, s.vehicle_id, s.started, s.stopped, "
           "  (SELECT COUNT(*) FROM telemetry t WHERE t.session_id = s.id) as entries "
           "FROM sessions s ORDER BY s.id DESC LIMIT 50");
    while (q.next()) {
        QVariantMap entry;
        entry["id"]        = q.value(0).toLongLong();
        entry["vehicleId"] = q.value(1).toString();
        entry["startTime"] = q.value(2).toString();

        QString stopped    = q.value(3).toString();
        QString started    = q.value(2).toString();
        int     durationSec = 0;
        if (!stopped.isEmpty() && !started.isEmpty()) {
            QDateTime s = QDateTime::fromString(started, Qt::ISODate);
            QDateTime e = QDateTime::fromString(stopped, Qt::ISODate);
            if (s.isValid() && e.isValid())
                durationSec = static_cast<int>(s.secsTo(e));
        }
        entry["duration"] = durationSec;
        entry["entries"]  = q.value(4).toInt();
        result.append(entry);
    }
    return result;
}

void FlightLogger::logTelemetry(double lat, double lon, double altRel,
                                 float roll, float pitch, float yaw,
                                 float groundSpeed, float climbRate,
                                 float battVoltage, int battPct,
                                 int gpsFixType, int gpsSats,
                                 const QString &flightMode, bool armed)
{
    if (!m_logging) return;

    // Buffer every sample rather than overwriting a single "latest" slot. The
    // telemetry rate is far higher than the 1 Hz write timer, so keeping only
    // the most recent value silently discarded intermediate samples and made
    // recorded tracks coarser than the data actually received.
    TelemetryRow row;
    row.sessionId   = m_sessionId;
    row.timestamp   = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
    row.lat         = lat;
    row.lon         = lon;
    row.altRel      = altRel;
    row.roll        = roll;
    row.pitch       = pitch;
    row.yaw         = yaw;
    row.groundSpeed = groundSpeed;
    row.climbRate   = climbRate;
    row.battVoltage = battVoltage;
    row.battPct     = battPct;
    row.gpsFixType  = gpsFixType;
    row.gpsSats     = gpsSats;
    row.flightMode  = flightMode;
    row.armed       = armed;

    m_pending.append(row);

    // Keep the in-memory buffer bounded if the database ever stalls, so a
    // logging failure cannot grow the process without limit mid-flight.
    if (m_pending.size() >= kMaxPendingRows)
        flushPending();
}

void FlightLogger::onWriteTimer()
{
    if (!m_logging) return;
    flushPending();
}

// ── Legacy API ───────────────────────────────────────────────────────────────

bool FlightLogger::startLog(const QString &label)
{
    startLogging(label);
    return m_logging;
}

void FlightLogger::stopLog()
{
    stopLogging();
}

QStringList FlightLogger::availableLogs() const
{
    QStringList result;
    QSqlQuery q("SELECT id, vehicle_id, started FROM sessions ORDER BY id DESC", m_db);
    while (q.next())
        result << QString("[%1] %2 — %3")
                    .arg(q.value(0).toLongLong())
                    .arg(q.value(1).toString())
                    .arg(q.value(2).toString());
    return result;
}

void FlightLogger::onTelemetryUpdated()
{
    if (!m_logging) return;
    if (!m_vehicleManager) return;

    Vehicle *v = m_vehicleManager->activeVehicle();
    if (!v || !v->telemetry()) return;

    const Telemetry *t = v->telemetry();
    const VehicleState &s = t->state();

    logTelemetry(s.latitude, s.longitude, s.altitudeRel,
                 s.roll  * 57.2958f,
                 s.pitch * 57.2958f,
                 s.yaw   * 57.2958f,
                 s.groundSpeed, s.climbRate,
                 s.batteryVoltage, s.batteryRemaining,
                 s.gpsFixType, s.gpsSatCount,
                 s.flightMode, s.armed);
}

void FlightLogger::flushPending()
{
    if (m_pending.isEmpty() || !m_db.isOpen()) return;

    if (!m_db.transaction()) {
        qCWarning(lcLog) << "Cannot begin transaction:" << m_db.lastError().text();
        return;
    }

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO telemetry(session_id,ts,lat,lon,alt_rel,"
        "roll,pitch,yaw,ground_spd,climb_rate,"
        "batt_v,batt_pct,gps_fix,gps_sats,flight_mode,armed) "
        "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"));

    int inserted = 0;
    for (const TelemetryRow &r : m_pending) {
        q.addBindValue(r.sessionId);
        q.addBindValue(r.timestamp);
        q.addBindValue(r.lat);   q.addBindValue(r.lon);   q.addBindValue(r.altRel);
        q.addBindValue(r.roll);  q.addBindValue(r.pitch); q.addBindValue(r.yaw);
        q.addBindValue(r.groundSpeed); q.addBindValue(r.climbRate);
        q.addBindValue(r.battVoltage); q.addBindValue(r.battPct);
        q.addBindValue(r.gpsFixType);  q.addBindValue(r.gpsSats);
        q.addBindValue(r.flightMode);  q.addBindValue(r.armed ? 1 : 0);

        if (!q.exec()) {
            // A failed row must not be counted as written, and the batch should
            // be abandoned rather than half-committed silently.
            qCWarning(lcLog) << "Telemetry insert failed:" << q.lastError().text();
            m_db.rollback();
            return;
        }
        ++inserted;
    }

    if (!m_db.commit()) {
        qCWarning(lcLog) << "Telemetry commit failed:" << m_db.lastError().text();
        m_db.rollback();
        return;
    }

    m_pending.clear();
    m_rowsWritten += inserted;
    emit rowsWritten(m_rowsWritten);
}

} // namespace IndigenousGCS
