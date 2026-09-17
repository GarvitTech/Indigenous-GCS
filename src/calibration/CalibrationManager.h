#pragma once
#include <QObject>
#include <QString>

namespace IndigenousGCS {

class MAVLinkManager;

class CalibrationManager : public QObject
{
    Q_OBJECT

public:
    enum class CalibrationTarget {
        Accelerometer = 0,
        Gyroscope     = 1,
        Magnetometer  = 2,
        Level         = 3,
        Radio         = 4,
        ESC           = 5
    };
    Q_ENUM(CalibrationTarget)

    enum class CalibrationStatus {
        Idle         = 0,
        InProgress   = 1,
        Complete     = 2,
        Failed       = 3,
        NotSupported = 4
    };
    Q_ENUM(CalibrationStatus)

    Q_PROPERTY(CalibrationStatus status   READ status   NOTIFY statusChanged)
    Q_PROPERTY(QString           message  READ message  NOTIFY messageChanged)
    Q_PROPERTY(int               progress READ progress NOTIFY progressChanged)

    explicit CalibrationManager(MAVLinkManager *mavlink, QObject *parent = nullptr);

    CalibrationStatus status()   const { return m_status; }
    QString           message()  const { return m_message; }
    int               progress() const { return m_progress; }

    Q_INVOKABLE void startCalibration(uint8_t targetSys, uint8_t targetComp,
                                      int target);  // int for QML
    Q_INVOKABLE void cancelCalibration();

signals:
    void statusChanged();
    void messageChanged();
    void progressChanged();

public slots:
    void onStatusText(int severity, const QString &text);

private:
    void setState(CalibrationStatus s, const QString &msg = {});

    MAVLinkManager   *m_mavlink;
    CalibrationStatus m_status   = CalibrationStatus::Idle;
    QString           m_message;
    int               m_progress = 0;
    uint8_t           m_targetSys  = 0;
    uint8_t           m_targetComp = 0;
};

} // namespace IndigenousGCS
