#pragma once
#include <QObject>
#include <QTimer>
#include <QString>

namespace IndigenousGCS {

// Safety levels (matches signal int parameter)
// 0=EMERGENCY, 1=CRITICAL, 2=WARNING, 3=INFO
enum class SafetyLevel { Emergency = 0, Critical = 1, Warning = 2, Info = 3 };

struct SafetyEvent {
    SafetyLevel level;
    QString     message;
};

class SafetyManager : public QObject
{
    Q_OBJECT
public:
    explicit SafetyManager(QObject *parent = nullptr);

    // Q_INVOKABLE so QML can call it directly
    Q_INVOKABLE void updateTelemetry(double battPct, int gpsFix, int satCount,
                                     bool hasHeartbeat, double roll, double pitch);

signals:
    // level: 0=EMERGENCY, 1=CRITICAL, 2=WARNING, 3=INFO
    void safetyEvent(int level, const QString &message);

private:
    void emit_(SafetyLevel level, const QString &msg);

    bool m_lowBatteryWarned    = false;  // battery < 20%
    bool m_critBatteryWarned   = false;  // battery < 10%
    bool m_gpsLossWarned       = false;
    bool m_heartbeatLossWarned = false;
    bool m_rollWarnActive      = false;
    bool m_pitchWarnActive     = false;
    bool m_hadGpsFix           = false;  // tracks if we ever had a good GPS fix
};

} // namespace IndigenousGCS
