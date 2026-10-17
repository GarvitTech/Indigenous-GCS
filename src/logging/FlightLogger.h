#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QDateTime>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

namespace IndigenousGCS {

class FlightLogger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLogging READ isLogging NOTIFY isLoggingChanged)
    // Keep old property name for backward compatibility
    Q_PROPERTY(bool logging   READ isLogging NOTIFY isLoggingChanged)

public:
    explicit FlightLogger(QObject *parent = nullptr);
    ~FlightLogger() override;

    bool isLogging() const { return m_logging; }
    // Keep old accessor for compat
    bool logging() const { return m_logging; }

    // New QML-friendly API
    Q_INVOKABLE void startLogging(const QString &vehicleId = {});
    Q_INVOKABLE void stopLogging();
    Q_INVOKABLE QVariantList getRecentLogs() const;

    // Legacy API (kept for backward compatibility)
    Q_INVOKABLE bool startLog(const QString &label = {});
    Q_INVOKABLE void stopLog();
    Q_INVOKABLE QStringList availableLogs() const;

    // Called externally to feed telemetry data into the logger
    // Parameters match what Vehicle/Telemetry provides
    Q_INVOKABLE void logTelemetry(double lat, double lon, double altRel,
                                  float roll, float pitch, float yaw,
                                  float groundSpeed, float climbRate,
                                  float battVoltage, int battPct,
                                  int gpsFixType, int gpsSats,
                                  const QString &flightMode, bool armed);

public slots:
    void onTelemetryUpdated();

signals:
    void isLoggingChanged();
    void loggingChanged();     // legacy alias
    void loggingStarted();
    void loggingStopped();

private:
    bool openDatabase(const QString &path);
    void createSchema();
    void flushPending();
    void onWriteTimer();

    QSqlDatabase m_db;
    QTimer       m_writeTimer;
    bool         m_logging   = false;
    qint64       m_sessionId = -1;
    QString      m_vehicleId;
    QString      m_dbPath;
    QDateTime    m_startTime;

    struct TelemetryRow {
        qint64  sessionId;
        QString timestamp;
        double  lat, lon, altRel;
        float   roll, pitch, yaw;
        float   groundSpeed, climbRate;
        float   battVoltage;
        int     battPct;
        int     gpsFixType, gpsSats;
        QString flightMode;
        bool    armed;
    };
    QList<TelemetryRow> m_pending;
    TelemetryRow        m_latestRow;
    bool                m_hasLatestRow = false;

    static constexpr int kFlushInterval = 10;
    static constexpr int kWriteIntervalMs = 1000; // write every 1 second
};

} // namespace IndigenousGCS
