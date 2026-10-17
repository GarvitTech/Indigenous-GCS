#include "FlightLogger.h"
#include "app/Application.h"
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
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_dbPath = dataDir + "/logs.db";
    openDatabase(m_dbPath);

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
    m_db = QSqlDatabase::addDatabase("QSQLITE", "flightlogger");
    m_db.setDatabaseName(path);
    if (!m_db.open()) {
        qCWarning(lcLog) << "Cannot open log DB:" << m_db.lastError().text();
        return false;
    }
    createSchema();
    return true;
}

void FlightLogger::createSchema()
{
    QSqlQuery q(m_db);
    q.exec("CREATE TABLE IF NOT EXISTS sessions ("
           "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  vehicle_id TEXT,"
           "  label      TEXT,"
           "  started    TEXT,"
           "  stopped    TEXT"
           ")");
    q.exec("CREATE TABLE IF NOT EXISTS telemetry ("
           "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  session_id  INTEGER,"
           "  ts          TEXT,"
           "  lat         REAL, lon REAL, alt_rel REAL,"
           "  roll        REAL, pitch REAL, yaw REAL,"
           "  ground_spd  REAL, climb_rate REAL,"
           "  batt_v      REAL, batt_pct INTEGER,"
           "  gps_fix     INTEGER, gps_sats INTEGER,"
           "  flight_mode TEXT, armed INTEGER"
           ")");
    q.exec("CREATE INDEX IF NOT EXISTS idx_tel_session ON telemetry(session_id)");
}

// ── New API ──────────────────────────────────────────────────────────────────

void FlightLogger::startLogging(const QString &vehicleId)
{
    if (m_logging) return;
    if (!m_db.isOpen()) return;

    m_vehicleId = vehicleId.isEmpty() ? "unknown" : vehicleId;
    m_startTime = QDateTime::currentDateTime();

    QSqlQuery q(m_db);
    q.prepare("INSERT INTO sessions(vehicle_id, label, started) VALUES(?,?,?)");
    q.addBindValue(m_vehicleId);
    q.addBindValue(m_startTime.toString("yyyy-MM-dd HH:mm:ss"));
    q.addBindValue(m_startTime.toUTC().toString(Qt::ISODate));
    if (!q.exec()) {
        qCWarning(lcLog) << "Failed to create session:" << q.lastError().text();
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
    flushPending();

    QSqlQuery q(m_db);
    q.prepare("UPDATE sessions SET stopped=? WHERE id=?");
    q.addBindValue(QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    q.addBindValue(m_sessionId);
    q.exec();

    m_logging   = false;
    m_sessionId = -1;
    m_hasLatestRow = false;
    emit isLoggingChanged();
    emit loggingChanged();
    emit loggingStopped();
    qCInfo(lcLog) << "Logging stopped";
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

    m_latestRow.sessionId   = m_sessionId;
    m_latestRow.timestamp   = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    m_latestRow.lat         = lat;
    m_latestRow.lon         = lon;
    m_latestRow.altRel      = altRel;
    m_latestRow.roll        = roll;
    m_latestRow.pitch       = pitch;
    m_latestRow.yaw         = yaw;
    m_latestRow.groundSpeed = groundSpeed;
    m_latestRow.climbRate   = climbRate;
    m_latestRow.battVoltage = battVoltage;
    m_latestRow.battPct     = battPct;
    m_latestRow.gpsFixType  = gpsFixType;
    m_latestRow.gpsSats     = gpsSats;
    m_latestRow.flightMode  = flightMode;
    m_latestRow.armed       = armed;
    m_hasLatestRow = true;
}

void FlightLogger::onWriteTimer()
{
    if (!m_logging || !m_hasLatestRow) return;
    m_pending.append(m_latestRow);
    if (m_pending.size() >= kFlushInterval)
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

    auto *app = Application::instance();
    if (!app) return;
    auto *vm = app->vehicleManager();
    if (!vm || !vm->activeVehicle()) return;

    const Telemetry *t = vm->activeVehicle()->telemetry();
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

    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO telemetry(session_id,ts,lat,lon,alt_rel,"
              "roll,pitch,yaw,ground_spd,climb_rate,"
              "batt_v,batt_pct,gps_fix,gps_sats,flight_mode,armed) "
              "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

    for (const TelemetryRow &r : m_pending) {
        q.addBindValue(r.sessionId);
        q.addBindValue(r.timestamp);
        q.addBindValue(r.lat);   q.addBindValue(r.lon);   q.addBindValue(r.altRel);
        q.addBindValue(r.roll);  q.addBindValue(r.pitch); q.addBindValue(r.yaw);
        q.addBindValue(r.groundSpeed); q.addBindValue(r.climbRate);
        q.addBindValue(r.battVoltage); q.addBindValue(r.battPct);
        q.addBindValue(r.gpsFixType);  q.addBindValue(r.gpsSats);
        q.addBindValue(r.flightMode);  q.addBindValue(r.armed ? 1 : 0);
        q.exec();
    }
    m_db.commit();
    m_pending.clear();
}

} // namespace IndigenousGCS
