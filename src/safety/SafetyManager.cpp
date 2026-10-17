#include "SafetyManager.h"
#include <cmath>

namespace IndigenousGCS {

SafetyManager::SafetyManager(QObject *parent) : QObject(parent) {}

void SafetyManager::updateTelemetry(double battPct, int gpsFix, int satCount,
                                     bool hasHeartbeat, double roll, double pitch)
{
    // ── Heartbeat loss ──────────────────────────────────────────────────────
    if (!hasHeartbeat && !m_heartbeatLossWarned) {
        m_heartbeatLossWarned = true;
        emit_(SafetyLevel::Critical, "Vehicle heartbeat lost — connection may be down");
    } else if (hasHeartbeat) {
        m_heartbeatLossWarned = false;
    }

    // ── Battery ─────────────────────────────────────────────────────────────
    if (battPct >= 0.0) {
        if (battPct <= 10.0 && !m_critBatteryWarned) {
            m_critBatteryWarned = true;
            emit_(SafetyLevel::Emergency,
                  QString("EMERGENCY: Battery critically low: %1%").arg(battPct, 0, 'f', 0));
        } else if (battPct <= 20.0 && !m_lowBatteryWarned) {
            m_lowBatteryWarned = true;
            emit_(SafetyLevel::Critical,
                  QString("CRITICAL: Low battery: %1%").arg(battPct, 0, 'f', 0));
        } else if (battPct > 25.0) {
            // Reset warnings once battery is back above threshold (e.g. different vehicle / sim restart)
            m_lowBatteryWarned  = false;
            m_critBatteryWarned = false;
        }
    }

    // ── GPS ─────────────────────────────────────────────────────────────────
    // Track if we ever had a good 3D fix
    if (gpsFix >= 3) {
        m_hadGpsFix = true;
        m_gpsLossWarned = false;
    }
    // Warn if we had a fix and now lost it
    if (m_hadGpsFix && gpsFix < 3 && !m_gpsLossWarned) {
        m_gpsLossWarned = true;
        emit_(SafetyLevel::Warning,
              QString("WARNING: GPS fix lost — fix=%1 sats=%2").arg(gpsFix).arg(satCount));
    }

    // ── Attitude ─────────────────────────────────────────────────────────────
    if (std::abs(roll) > 60.0 && !m_rollWarnActive) {
        m_rollWarnActive = true;
        emit_(SafetyLevel::Warning,
              QString("WARNING: Extreme roll: %1°").arg(roll, 0, 'f', 1));
    } else if (std::abs(roll) <= 60.0) {
        m_rollWarnActive = false;
    }

    if (std::abs(pitch) > 45.0 && !m_pitchWarnActive) {
        m_pitchWarnActive = true;
        emit_(SafetyLevel::Warning,
              QString("WARNING: Extreme pitch: %1°").arg(pitch, 0, 'f', 1));
    } else if (std::abs(pitch) <= 45.0) {
        m_pitchWarnActive = false;
    }
}

void SafetyManager::emit_(SafetyLevel level, const QString &msg)
{
    emit safetyEvent(static_cast<int>(level), msg);
}

} // namespace IndigenousGCS
