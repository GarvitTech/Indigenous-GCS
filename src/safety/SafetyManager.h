#pragma once
#include <QObject>
#include <QTimer>
#include <QString>

namespace IndigenousGCS {

enum class SafetyLevel { Info = 0, Warning = 1, Critical = 2, Emergency = 3 };

struct SafetyEvent {
    SafetyLevel level;
    QString     message;
};

class SafetyManager : public QObject
{
    Q_OBJECT
public:
    explicit SafetyManager(QObject *parent = nullptr);

    void updateTelemetry(float batteryPct, int gpsFixType,
                         int gpsSats, bool heartbeatAlive,
                         float roll, float pitch);

signals:
    // level is int (0=Info,1=Warning,2=Critical,3=Emergency) for QML compatibility
    void safetyEvent(int level, const QString &message);

private:
    void emit_(SafetyLevel level, const QString &msg);

    bool m_lowBatteryWarned   = false;
    bool m_critBatteryWarned  = false;
    bool m_gpsLossWarned      = false;
    bool m_heartbeatLossWarned = false;
};

} // namespace IndigenousGCS
