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

class VehicleManager;

class FlightLogger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLogging READ isLogging NOTIFY isLoggingChanged)
    // Keep old property name for backward compatibility
    Q_PROPERTY(bool logging   READ isLogging NOTIFY isLoggingChanged)

public:
    explicit FlightLogger(QObject *parent = nullptr);
    ~FlightLogger() override;

    /**
     * Supply the vehicle source for onTelemetryUpdated().
     *
     * This is injected rather than fetched from Application::instance() so the
     * logger can be constructed and driven in isolation by tests, and so the
     * dependency is visible in the header instead of hidden in the .cpp.
     */
    void setVehicleManager(VehicleManager *manager) { m_vehicleManager = manager; }

    bool isLogging() const { return m_logging; }
    // Keep old accessor for compat
    bool logging() const { return m_logging; }

    // New QML-friendly API
    Q_INVOKABLE void startLogging(const QString &vehicleId = {});
    Q_INVOKABLE void stopLogging();
    Q_INVOKABLE QVariantList getRecentLogs() const;

    /// Absolute path of the database being written, for display in the UI so a
    /// logging problem can be diagnosed without guessing.
    Q_INVOKABLE QString databasePath() const { return m_dbPath; }

    /// Number of telemetry rows in the current session. Zero while recording
    /// means no telemetry is reaching the logger.
    Q_INVOKABLE int currentSessionRowCount() const;

    /// True when the database opened successfully and logging can work at all.
    Q_INVOKABLE bool isAvailable() const { return m_db.isOpen(); }

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
    /// Emitted when logging could not start, with a human-readable reason.
    void loggingFailed(const QString &reason);
    /// Emitted after each successful flush so the UI can show a live row count.
    void rowsWritten(int totalRows);

private:
    bool openDatabase(const QString &path);
    void createSchema();
    void flushPending();
    void onWriteTimer();

    QSqlDatabase m_db;
    QTimer       m_writeTimer;
    VehicleManager *m_vehicleManager = nullptr;
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
    int                 m_rowsWritten  = 0;

    // Safety cap on the in-memory buffer. If the database stalls, the oldest
    // rows are dropped rather than letting memory grow unbounded during a
    // flight; the cap is far above any realistic 1-second flush backlog.
    static constexpr int kMaxPendingRows  = 600;
    static constexpr int kWriteIntervalMs = 1000; // flush every 1 second
};

} // namespace IndigenousGCS
