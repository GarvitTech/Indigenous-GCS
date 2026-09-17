#include "SafetyManager.h"
#include <cmath>

namespace IndigenousGCS {

SafetyManager::SafetyManager(QObject *parent) : QObject(parent) {}

void SafetyManager::updateTelemetry(float batteryPct, int gpsFixType,
                                     int gpsSats, bool heartbeatAlive,
                                     float roll, float pitch)
{
    // Heartbeat loss
    if (!heartbeatAlive && !m_heartbeatLossWarned) {
        m_heartbeatLossWarned = true;
        emit_(SafetyLevel::Critical, "Vehicle heartbeat lost — connection may be down");
    } else if (heartbeatAlive) {
        m_heartbeatLossWarned = false;
    }

    // Battery
    if (batteryPct >= 0) {
        if (batteryPct <= 10.0f && !m_critBatteryWarned) {
            m_critBatteryWarned = true;
            emit_(SafetyLevel::Emergency, QString("CRITICAL battery: %1%").arg(batteryPct, 0, 'f', 0));
        } else if (batteryPct <= 25.0f && !m_lowBatteryWarned) {
            m_lowBatteryWarned = true;
            emit_(SafetyLevel::Warning, QString("Low battery: %1%").arg(batteryPct, 0, 'f', 0));
        } else if (batteryPct > 30.0f) {
            m_lowBatteryWarned  = false;
            m_critBatteryWarned = false;
        }
    }

    // GPS
    if (gpsFixType < 3 && gpsSats < 6 && !m_gpsLossWarned) {
        m_gpsLossWarned = true;
        emit_(SafetyLevel::Warning, QString("Poor GPS: fix=%1 sats=%2").arg(gpsFixType).arg(gpsSats));
    } else if (gpsFixType >= 3 && gpsSats >= 6) {
        m_gpsLossWarned = false;
    }

    // Attitude anomaly (>60 deg)
    if (std::abs(roll) > 60.0f || std::abs(pitch) > 60.0f)
        emit_(SafetyLevel::Critical, QString("Extreme attitude: roll=%1° pitch=%2°")
              .arg(roll, 0, 'f', 1).arg(pitch, 0, 'f', 1));
}

void SafetyManager::emit_(SafetyLevel level, const QString &msg)
{
    emit safetyEvent(static_cast<int>(level), msg);
}

} // namespace IndigenousGCS
