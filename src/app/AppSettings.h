#pragma once
#include <QObject>
#include <QString>
#include "utils/Units.h"

namespace IndigenousGCS {

class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int    unitSystem      READ unitSystem      WRITE setUnitSystem      NOTIFY unitSystemChanged)
    Q_PROPERTY(int    gcsSystemId     READ gcsSystemId     WRITE setGcsSystemId     NOTIFY gcsSystemIdChanged)
    Q_PROPERTY(int    gcsComponentId  READ gcsComponentId  WRITE setGcsComponentId  NOTIFY gcsComponentIdChanged)
    Q_PROPERTY(QString serialPort     READ serialPort      WRITE setSerialPort      NOTIFY serialPortChanged)
    Q_PROPERTY(int    serialBaud      READ serialBaud      WRITE setSerialBaud      NOTIFY serialBaudChanged)
    Q_PROPERTY(QString udpHost        READ udpHost         WRITE setUdpHost         NOTIFY udpHostChanged)
    Q_PROPERTY(int    udpPort         READ udpPort         WRITE setUdpPort         NOTIFY udpPortChanged)
    Q_PROPERTY(bool   autoConnect     READ autoConnect     WRITE setAutoConnect     NOTIFY autoConnectChanged)
    Q_PROPERTY(bool   confirmArm      READ confirmArm      WRITE setConfirmArm      NOTIFY confirmArmChanged)
    Q_PROPERTY(bool   confirmMission  READ confirmMission  WRITE setConfirmMission  NOTIFY confirmMissionChanged)
    Q_PROPERTY(bool   lightTheme      READ lightTheme      WRITE setLightTheme      NOTIFY lightThemeChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    void load();
    void save();

    int     unitSystem()     const { return m_unitSystem; }
    int     gcsSystemId()    const { return m_gcsSystemId; }
    int     gcsComponentId() const { return m_gcsComponentId; }
    QString serialPort()     const { return m_serialPort; }
    int     serialBaud()     const { return m_serialBaud; }
    QString udpHost()        const { return m_udpHost; }
    int     udpPort()        const { return m_udpPort; }
    bool    autoConnect()    const { return m_autoConnect; }
    bool    confirmArm()     const { return m_confirmArm; }
    bool    confirmMission() const { return m_confirmMission; }
    bool    lightTheme()      const { return m_lightTheme; }

    Units::System units() const {
        return m_unitSystem == 0 ? Units::System::Metric : Units::System::Imperial;
    }

public slots:
    void setUnitSystem(int v);
    void setGcsSystemId(int v);
    void setGcsComponentId(int v);
    void setSerialPort(const QString &v);
    void setSerialBaud(int v);
    void setUdpHost(const QString &v);
    void setUdpPort(int v);
    void setAutoConnect(bool v);
    void setConfirmArm(bool v);
    void setConfirmMission(bool v);
    void setLightTheme(bool v);

signals:
    void unitSystemChanged();
    void gcsSystemIdChanged();
    void gcsComponentIdChanged();
    void serialPortChanged();
    void serialBaudChanged();
    void udpHostChanged();
    void udpPortChanged();
    void autoConnectChanged();
    void confirmArmChanged();
    void confirmMissionChanged();
    void lightThemeChanged();

private:
    int     m_unitSystem     = 0;       // 0=Metric, 1=Imperial
    int     m_gcsSystemId    = 255;
    int     m_gcsComponentId = 190;
    QString m_serialPort;
    int     m_serialBaud     = 115200;
    QString m_udpHost        = "127.0.0.1";
    int     m_udpPort        = 14550;
    bool    m_autoConnect    = false;
    bool    m_confirmArm     = true;
    bool    m_confirmMission = true;
    bool    m_lightTheme     = false;
};

} // namespace IndigenousGCS
