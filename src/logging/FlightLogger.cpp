#include "FlightLogger.h"
#include "app/Application.h"
#include "vehicle/VehicleManager.h"
#include "vehicle/Vehicle.h"
#include "vehicle/Telemetry.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcLog, "igcs.logger")

namespace IndigenousGCS {

FlightLogger::FlightLogger(QObject *parent) : QObject(parent)
{
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_dbPath = dataDir + "/flightlogs.db";
    openDatabase(m_dbPath);
}

FlightLogger::~FlightLogger()
{
    stopLog();
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
           "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  label     TEXT,"
           "  started   TEXT,"
           "  stopped   TEXT"
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

bool FlightLogger::startLog(const QString &label)
{
    if (m_logging) return true;
    if (!m_db.isOpen()) return false;

    QSqlQuery q(m_db);
    q.prepare("INSERT INTO sessions(label, started) VALUES(?,?)");
    q.addBindValue(label.isEmpty() ? QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss") : label);
    q.addBindValue(QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    if (!q.exec()) {
        qCWarning(lcLog) << "Failed to create session:" << q.lastError().text();
        return false;
    }
    m_sessionId = q.lastInsertId().toLongLong();
    m_logging   = true;
    emit loggingChanged();
    qCInfo(lcLog) << "Log started, session=" << m_sessionId;
    return true;
}

void FlightLogger::stopLog()
{
    if (!m_logging) return;
    flushPending();

    QSqlQuery q(m_db);
    q.prepare("UPDATE sessions SET stopped=? WHERE id=?");
    q.addBindValue(QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    q.addBindValue(m_sessionId);
    q.exec();

    m_logging   = false;
    m_sessionId = -1;
    emit loggingChanged();
    qCInfo(lcLog) << "Log stopped";
}

QStringList FlightLogger::availableLogs() const
{
    QStringList result;
    QSqlQuery q("SELECT id, label, started FROM sessions ORDER BY id DESC", m_db);
    while (q.next())
        result << QString("[%1] %2 — %3").arg(q.value(0).toLongLong())
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

    TelemetryRow row;
    row.sessionId   = m_sessionId;
    row.timestamp   = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    row.lat         = s.latitude;
    row.lon         = s.longitude;
    row.altRel      = s.altitudeRel;
    row.roll        = s.roll  * 57.2958f;
    row.pitch       = s.pitch * 57.2958f;
    row.yaw         = s.yaw   * 57.2958f;
    row.groundSpeed = s.groundSpeed;
    row.climbRate   = s.climbRate;
    row.battVoltage = s.batteryVoltage;
    row.battPct     = s.batteryRemaining;
    row.gpsFixType  = s.gpsFixType;
    row.gpsSats     = s.gpsSatCount;
    row.flightMode  = s.flightMode;
    row.armed       = s.armed;
    m_pending.append(row);

    if (m_pending.size() >= kFlushInterval)
        flushPending();
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
