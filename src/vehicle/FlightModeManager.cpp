#include "FlightModeManager.h"

namespace IndigenousGCS {

FlightModeManager::FlightModeManager(QObject *parent) : QObject(parent)
{
    // ArduCopter custom mode numbers (also used by many ESP32 FC implementations)
    const QList<QPair<uint32_t, QString>> modes = {
        {0,  "Stabilize"},
        {1,  "Acro"},
        {2,  "Alt Hold"},
        {3,  "Auto"},
        {4,  "Guided"},
        {5,  "Loiter"},
        {6,  "RTL"},
        {7,  "Circle"},
        {9,  "Land"},
        {11, "Drift"},
        {13, "Sport"},
        {16, "PosHold"},
        {17, "Brake"},
        {18, "Throw"},
    };

    for (const auto &[id, name] : modes) {
        m_modeNames[id]   = name;
        m_nameToMode[name] = id;
    }
}

QString FlightModeManager::modeNameFromCustom(uint32_t customMode) const
{
    return m_modeNames.value(customMode, QString("Mode %1").arg(customMode));
}

uint32_t FlightModeManager::customModeFromName(const QString &name) const
{
    return m_nameToMode.value(name, 0);
}

QStringList FlightModeManager::availableModes() const
{
    QStringList list;
    for (auto it = m_modeNames.constBegin(); it != m_modeNames.constEnd(); ++it)
        list.append(it.value());
    list.sort();
    return list;
}

uint8_t FlightModeManager::baseModeForCustom(uint32_t /*customMode*/, bool armed) const
{
    // MAV_MODE_FLAG_CUSTOM_MODE_ENABLED | MAV_MODE_FLAG_STABILIZE_ENABLED
    // plus armed flag when needed
    uint8_t base = 0x01 | 0x10; // CUSTOM_MODE_ENABLED | STABILIZE
    if (armed)
        base |= 0x80; // MAV_MODE_FLAG_SAFETY_ARMED
    return base;
}

} // namespace IndigenousGCS
