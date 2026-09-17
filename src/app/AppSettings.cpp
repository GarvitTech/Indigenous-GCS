#include "AppSettings.h"
#include <QSettings>

namespace IndigenousGCS {

AppSettings::AppSettings(QObject *parent) : QObject(parent) { load(); }

void AppSettings::load()
{
    QSettings s;
    m_unitSystem     = s.value("app/unitSystem",     0).toInt();
    m_gcsSystemId    = s.value("app/gcsSystemId",    255).toInt();
    m_gcsComponentId = s.value("app/gcsComponentId", 190).toInt();
    m_serialPort     = s.value("serial/port",        "").toString();
    m_serialBaud     = s.value("serial/baud",        115200).toInt();
    m_udpHost        = s.value("udp/host",           "127.0.0.1").toString();
    m_udpPort        = s.value("udp/port",           14550).toInt();
    m_autoConnect    = s.value("app/autoConnect",    false).toBool();
    m_confirmArm     = s.value("app/confirmArm",     true).toBool();
    m_confirmMission = s.value("app/confirmMission", true).toBool();
    m_lightTheme     = s.value("app/lightTheme", false).toBool();
}

void AppSettings::save()
{
    QSettings s;
    s.setValue("app/unitSystem",     m_unitSystem);
    s.setValue("app/gcsSystemId",    m_gcsSystemId);
    s.setValue("app/gcsComponentId", m_gcsComponentId);
    s.setValue("serial/port",        m_serialPort);
    s.setValue("serial/baud",        m_serialBaud);
    s.setValue("udp/host",           m_udpHost);
    s.setValue("udp/port",           m_udpPort);
    s.setValue("app/autoConnect",    m_autoConnect);
    s.setValue("app/confirmArm",     m_confirmArm);
    s.setValue("app/confirmMission", m_confirmMission);
    s.setValue("app/lightTheme",     m_lightTheme);
}

#define SETTER(Type, name, Name, signal) \
void AppSettings::set##Name(Type v) { \
    if (m_##name == v) return; \
    m_##name = v; \
    save(); \
    emit signal(); \
}

SETTER(int,     unitSystem,     UnitSystem,     unitSystemChanged)
SETTER(int,     gcsSystemId,    GcsSystemId,    gcsSystemIdChanged)
SETTER(int,     gcsComponentId, GcsComponentId, gcsComponentIdChanged)
SETTER(int,     serialBaud,     SerialBaud,     serialBaudChanged)
SETTER(int,     udpPort,        UdpPort,        udpPortChanged)
SETTER(bool,    autoConnect,    AutoConnect,    autoConnectChanged)
SETTER(bool,    confirmArm,     ConfirmArm,     confirmArmChanged)
SETTER(bool,    confirmMission, ConfirmMission, confirmMissionChanged)
SETTER(bool,    lightTheme,     LightTheme,     lightThemeChanged)

void AppSettings::setSerialPort(const QString &v) {
    if (m_serialPort == v) return;
    m_serialPort = v; save(); emit serialPortChanged();
}
void AppSettings::setUdpHost(const QString &v) {
    if (m_udpHost == v) return;
    m_udpHost = v; save(); emit udpHostChanged();
}

} // namespace IndigenousGCS
