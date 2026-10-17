#include "AppSettings.h"
#include <QSettings>
#include <QDir>
#include <QFile>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDesktopServices>
#include <QEventLoop>
#include <QTimer>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcSettings, "igcs.settings")

namespace IndigenousGCS {

AppSettings::AppSettings(QObject *parent) : QObject(parent) { load(); }

void AppSettings::load()
{
    QSettings s;
    m_unitSystem      = s.value("app/unitSystem",      0).toInt();
    m_gcsSystemId     = s.value("app/gcsSystemId",     255).toInt();
    m_gcsComponentId  = s.value("app/gcsComponentId",  190).toInt();
    m_serialPort      = s.value("serial/port",         "").toString();
    m_serialBaud      = s.value("serial/baud",         115200).toInt();
    m_udpHost         = s.value("udp/host",            "127.0.0.1").toString();
    m_udpPort         = s.value("udp/port",            14550).toInt();
    m_autoConnect     = s.value("app/autoConnect",     false).toBool();
    m_confirmArm      = s.value("app/confirmArm",      true).toBool();
    m_confirmMission  = s.value("app/confirmMission",  true).toBool();
    m_lightTheme      = s.value("app/lightTheme",      false).toBool();
    m_mapProvider     = s.value("app/mapProvider",     "osm").toString();
    m_telemetryRateHz = s.value("app/telemetryRateHz", 4).toInt();
}

void AppSettings::save()
{
    QSettings s;
    s.setValue("app/unitSystem",      m_unitSystem);
    s.setValue("app/gcsSystemId",     m_gcsSystemId);
    s.setValue("app/gcsComponentId",  m_gcsComponentId);
    s.setValue("serial/port",         m_serialPort);
    s.setValue("serial/baud",         m_serialBaud);
    s.setValue("udp/host",            m_udpHost);
    s.setValue("udp/port",            m_udpPort);
    s.setValue("app/autoConnect",     m_autoConnect);
    s.setValue("app/confirmArm",      m_confirmArm);
    s.setValue("app/confirmMission",  m_confirmMission);
    s.setValue("app/lightTheme",      m_lightTheme);
    s.setValue("app/mapProvider",     m_mapProvider);
    s.setValue("app/telemetryRateHz", m_telemetryRateHz);
}

#define SETTER(Type, name, Name, signal) \
void AppSettings::set##Name(Type v) { \
    if (m_##name == v) return; \
    m_##name = v; \
    save(); \
    emit signal(); \
}

SETTER(int,  unitSystem,      UnitSystem,      unitSystemChanged)
SETTER(int,  gcsSystemId,     GcsSystemId,     gcsSystemIdChanged)
SETTER(int,  gcsComponentId,  GcsComponentId,  gcsComponentIdChanged)
SETTER(int,  serialBaud,      SerialBaud,      serialBaudChanged)
SETTER(int,  udpPort,         UdpPort,         udpPortChanged)
SETTER(bool, autoConnect,     AutoConnect,     autoConnectChanged)
SETTER(bool, confirmArm,      ConfirmArm,      confirmArmChanged)
SETTER(bool, confirmMission,  ConfirmMission,  confirmMissionChanged)
SETTER(bool, lightTheme,      LightTheme,      lightThemeChanged)
SETTER(int,  telemetryRateHz, TelemetryRateHz, telemetryRateHzChanged)

void AppSettings::setSerialPort(const QString &v) {
    if (m_serialPort == v) return;
    m_serialPort = v; save(); emit serialPortChanged();
}
void AppSettings::setUdpHost(const QString &v) {
    if (m_udpHost == v) return;
    m_udpHost = v; save(); emit udpHostChanged();
}
void AppSettings::setMapProvider(const QString &v) {
    if (m_mapProvider == v) return;
    m_mapProvider = v; save(); emit mapProviderChanged();
}
void AppSettings::setUnitSystemStr(const QString &v) {
    int newVal = (v.toLower() == "imperial") ? 1 : 0;
    if (m_unitSystem == newVal) return;
    m_unitSystem = newVal;
    save();
    emit unitSystemChanged();
    emit unitSystemStrChanged();
}

// ── User guide ───────────────────────────────

QString AppSettings::guideFilePath() const
{
    // The guide lives in the Qt resource system so it ships inside the binary
    // and cannot go missing. External browsers cannot open qrc:/ URLs, so the
    // resource is extracted once to a stable temp path and that path is
    // returned. Writing it each time would be wasteful, so an existing file of
    // non-zero size is reused.
    const QString target = QDir(QDir::tempPath())
                               .filePath(QStringLiteral("IndigenousGCS-guide.html"));

    QFile out(target);
    if (out.exists() && out.size() > 0)
        return target;

    QFile in(QStringLiteral(":/docs/guide.html"));
    if (!in.open(QIODevice::ReadOnly)) {
        qCWarning(lcSettings) << "Bundled guide resource missing: :/docs/guide.html";
        return QString();
    }
    const QByteArray html = in.readAll();
    in.close();

    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qCWarning(lcSettings) << "Cannot extract guide to" << target << out.errorString();
        return QString();
    }
    out.write(html);
    out.close();
    return target;
}

bool AppSettings::openGuide() const
{
    const QString path = guideFilePath();
    if (path.isEmpty()) {
        emit const_cast<AppSettings *>(this)->locationDetectionFailed(
            tr("The user guide could not be opened — its resource is missing."));
        return false;
    }

    // QDesktopServices picks the correct handler per platform: the default
    // browser on Windows, the default browser on macOS, xdg-open on Linux.
    const bool ok = QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    if (!ok)
        qCWarning(lcSettings) << "Failed to hand the guide to the system browser:" << path;
    return ok;
}

// ── Approximate location from public IP ──────────────────────

QVariantMap AppSettings::detectLocation()
{
    if (m_locationResolved)
        return m_cachedLocation;

    QVariantMap result;

    // A short-timeout synchronous request. This runs once per session, on
    // first use of the map, and the endpoint is tiny. Blocking briefly here is
    // preferable to a map that silently opens in the wrong country, and the
    // 3-second cap keeps the worst case bounded if the network is black-holed.
    QNetworkAccessManager nam;
    QNetworkRequest req(QUrl(QStringLiteral("http://ip-api.com/json/?fields=status,lat,lon,city,country,message")));
    req.setTransferTimeout(3000);
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("IndigenousGCS/1.0"));

    QNetworkReply *reply = nam.get(req);
    QEventLoop loop;
    QTimer guard;
    guard.setSingleShot(true);
    guard.setInterval(4000);

    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    QObject::connect(&guard, &QTimer::timeout, &loop, &QEventLoop::quit);
    guard.start();
    loop.exec();

    if (reply->isFinished() && reply->error() == QNetworkReply::NoError) {
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        const QJsonObject obj = doc.object();
        if (obj.value(QStringLiteral("status")).toString() == QLatin1String("success")) {
            const double lat = obj.value(QStringLiteral("lat")).toDouble();
            const double lon = obj.value(QStringLiteral("lon")).toDouble();
            if (lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0) {
                result[QStringLiteral("valid")]     = true;
                result[QStringLiteral("latitude")]  = lat;
                result[QStringLiteral("longitude")] = lon;
                result[QStringLiteral("city")]      = obj.value(QStringLiteral("city")).toString();
                result[QStringLiteral("country")]   = obj.value(QStringLiteral("country")).toString();
                m_cachedLocation   = result;
                m_locationResolved = true;
                qCInfo(lcSettings) << "Location resolved:" << result["city"].toString()
                                   << lat << lon;
                emit locationDetected(lat, lon, result[QStringLiteral("city")].toString());
                reply->deleteLater();
                return result;
            }
        }
        qCWarning(lcSettings) << "Location lookup returned no usable coordinates";
    } else {
        qCWarning(lcSettings) << "Location lookup failed:" << reply->errorString();
    }

    // Not an error the operator needs to act on — the map simply falls back to
    // a default centre. Report it as a failure so the UI can say so, but do not
    // cache it, so a later retry (e.g. after Wi-Fi reconnects) can succeed.
    reply->deleteLater();
    emit locationDetectionFailed(tr("Could not determine your location; using the default map centre."));
    result[QStringLiteral("valid")] = false;
    return result;
}

} // namespace IndigenousGCS
