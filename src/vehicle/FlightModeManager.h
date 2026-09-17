#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include <QHash>

namespace IndigenousGCS {

class FlightModeManager : public QObject
{
    Q_OBJECT
public:
    explicit FlightModeManager(QObject *parent = nullptr);

    QString     modeNameFromCustom(uint32_t customMode) const;
    uint32_t    customModeFromName(const QString &name) const;
    QStringList availableModes() const;
    uint8_t     baseModeForCustom(uint32_t customMode, bool armed) const;

private:
    QHash<uint32_t, QString> m_modeNames;
    QHash<QString, uint32_t> m_nameToMode;
};

} // namespace IndigenousGCS
