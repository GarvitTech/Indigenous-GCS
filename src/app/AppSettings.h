#pragma once
#include <QObject>
#include <QString>
#include <QVariantMap>
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
    Q_PROPERTY(QString mapProvider    READ mapProvider     WRITE setMapProvider     NOTIFY mapProviderChanged)
    Q_PROPERTY(int    telemetryRateHz READ telemetryRateHz WRITE setTelemetryRateHz NOTIFY telemetryRateHzChanged)
    Q_PROPERTY(QString unitSystemStr  READ unitSystemStr   WRITE setUnitSystemStr   NOTIFY unitSystemStrChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    void load();
    void save();

    int     unitSystem()      const { return m_unitSystem; }
    int     gcsSystemId()     const { return m_gcsSystemId; }
    int     gcsComponentId()  const { return m_gcsComponentId; }
    QString serialPort()      const { return m_serialPort; }
    int     serialBaud()      const { return m_serialBaud; }
    QString udpHost()         const { return m_udpHost; }
    int     udpPort()         const { return m_udpPort; }
    bool    autoConnect()     const { return m_autoConnect; }
    bool    confirmArm()      const { return m_confirmArm; }
    bool    confirmMission()  const { return m_confirmMission; }
    bool    lightTheme()      const { return m_lightTheme; }
    QString mapProvider()     const { return m_mapProvider; }
    int     telemetryRateHz() const { return m_telemetryRateHz; }
    QString unitSystemStr()   const { return m_unitSystem == 0 ? "metric" : "imperial"; }

    Units::System units() const {
        return m_unitSystem == 0 ? Units::System::Metric : Units::System::Imperial;
    }

    /// Open the bundled HTML user guide in the system web browser.
    /// Returns false if the resource is missing or no browser could be launched.
    Q_INVOKABLE bool openGuide() const;

    /// Absolute filesystem path to the extracted guide, or an empty string.
    /// The guide is compiled into the binary as a Qt resource and extracted to
    /// a temp file on first use, because external browsers cannot read qrc:/ .
    Q_INVOKABLE QString guideFilePath() const;

    /// Approximate location of this computer, resolved from its public IP
    /// address. Returns an invalid QVariantMap when offline or rate-limited.
    /// The result is cached for the lifetime of the process.
    Q_INVOKABLE QVariantMap detectLocation();

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
    void setMapProvider(const QString &v);
    void setTelemetryRateHz(int v);
    void setUnitSystemStr(const QString &v);

signals:
    void locationDetected(double latitude, double longitude, const QString &city);
    void locationDetectionFailed(const QString &reason);
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
    void mapProviderChanged();
    void telemetryRateHzChanged();
    void unitSystemStrChanged();

private:
    int     m_unitSystem      = 0;       // 0=Metric, 1=Imperial
    int     m_gcsSystemId     = 255;
    int     m_gcsComponentId  = 190;
    QString m_serialPort;
    int     m_serialBaud      = 115200;
    QString m_udpHost         = "127.0.0.1";
    int     m_udpPort         = 14550;
    bool    m_autoConnect     = false;
    bool    m_confirmArm      = true;
    bool    m_confirmMission  = true;
    bool    m_lightTheme      = false;
    QString m_mapProvider     = "osm";
    int     m_telemetryRateHz = 4;

    // IP geolocation is cached so the map centre is stable across page loads
    // and we never hammer the lookup service more than once per session.
    mutable bool        m_locationResolved = false;
    mutable QVariantMap m_cachedLocation;
};

} // namespace IndigenousGCS
