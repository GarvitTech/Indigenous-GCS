#include "CalibrationManager.h"
#include "mavlink/MAVLinkManager.h"
#include "mavlink/MAVLinkSender.h"
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcCalib, "igcs.calibration")

namespace IndigenousGCS {

CalibrationManager::CalibrationManager(MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent), m_mavlink(mavlink) {}

void CalibrationManager::startCalibration(uint8_t targetSys, uint8_t targetComp,
                                           int targetInt)
{
    const auto target = static_cast<CalibrationTarget>(targetInt);
    m_targetSys  = targetSys;
    m_targetComp = targetComp;
    m_progress   = 0;

    // MAV_CMD_PREFLIGHT_CALIBRATION params:
    // p1=gyro, p2=mag, p3=ground_pressure, p4=radio, p5=accel, p6=compass_motor, p7=esc
    float p1=0,p2=0,p3=0,p4=0,p5=0,p6=0,p7=0;

    switch (target) {
    case CalibrationTarget::Gyroscope:
        p1 = 1; setState(CalibrationStatus::InProgress, "Gyroscope calibration started. Keep vehicle still.");
        break;
    case CalibrationTarget::Magnetometer:
        p2 = 1; setState(CalibrationStatus::InProgress, "Magnetometer calibration started. Rotate vehicle.");
        break;
    case CalibrationTarget::Accelerometer:
        p5 = 1; setState(CalibrationStatus::InProgress, "Accelerometer calibration started. Follow instructions.");
        break;
    case CalibrationTarget::Level:
        p5 = 2; setState(CalibrationStatus::InProgress, "Level calibration started. Place vehicle on flat surface.");
        break;
    case CalibrationTarget::Radio:
        p4 = 1; setState(CalibrationStatus::InProgress, "Radio calibration started. Move all sticks to extremes.");
        break;
    case CalibrationTarget::ESC:
        p7 = 1; setState(CalibrationStatus::InProgress, "ESC calibration started.");
        break;
    }

    m_mavlink->sender()->sendCommandLong(targetSys, targetComp,
                                         MAV_CMD_PREFLIGHT_CALIBRATION,
                                         p1, p2, p3, p4, p5, p6, p7);
    qCInfo(lcCalib) << "Calibration started for target" << static_cast<int>(target);
}

void CalibrationManager::cancelCalibration()
{
    // Send zero params to cancel
    m_mavlink->sender()->sendCommandLong(m_targetSys, m_targetComp,
                                         MAV_CMD_PREFLIGHT_CALIBRATION,
                                         0,0,0,0,0,0,0);
    setState(CalibrationStatus::Idle, "Calibration cancelled.");
}

void CalibrationManager::onStatusText(int /*severity*/, const QString &text)
{
    if (m_status != CalibrationStatus::InProgress) return;

    const QString lower = text.toLower();
    if (lower.contains("calibration successful") || lower.contains("calibration complete")) {
        m_progress = 100;
        emit progressChanged();
        setState(CalibrationStatus::Complete, text);
    } else if (lower.contains("calibration failed") || lower.contains("error")) {
        setState(CalibrationStatus::Failed, text);
    } else if (lower.contains("calibrat")) {
        m_message = text;
        emit messageChanged();
        // Increment progress heuristically
        if (m_progress < 90) { m_progress += 10; emit progressChanged(); }
    }
}

void CalibrationManager::setState(CalibrationStatus s, const QString &msg)
{
    m_status  = s;
    m_message = msg;
    emit statusChanged();
    emit messageChanged();
}

} // namespace IndigenousGCS
