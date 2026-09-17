#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QDateTime>
#include <QString>

namespace IndigenousGCS {

class FlightLogger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool logging READ logging NOTIFY loggingChanged)

public:
    explicit FlightLogger(QObject *parent = nullptr);
    ~FlightLogger() override;

    bool logging() const { return m_logging; }

    Q_INVOKABLE bool startLog(const QString &label = {});
    Q_INVOKABLE void stopLog();
    Q_INVOKABLE QStringList availableLogs() const;

public slots:
    void onTelemetryUpdated();

signals:
    void loggingChanged();

private:
    bool openDatabase(const QString &path);
    void createSchema();
    void flushPending();

    QSqlDatabase m_db;
    bool         m_logging   = false;
    qint64       m_sessionId = -1;
    QString      m_dbPath;

    // Pending row buffer (flush every N updates)
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
    static constexpr int kFlushInterval = 10;
};

} // namespace IndigenousGCS
