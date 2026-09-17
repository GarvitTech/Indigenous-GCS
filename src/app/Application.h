#pragma once
#include <QObject>
#include <memory>

namespace IndigenousGCS {

class AppSettings;
class ConnectionManager;
class MAVLinkManager;
class VehicleManager;
class FlightLogger;

class Application : public QObject
{
    Q_OBJECT
public:
    explicit Application(QObject *parent = nullptr);
    ~Application() override;

    static Application *instance();

    AppSettings       *settings()           const { return m_settings.get(); }
    ConnectionManager *connectionManager()  const { return m_connectionManager.get(); }
    MAVLinkManager    *mavlinkManager()     const { return m_mavlinkManager.get(); }
    VehicleManager    *vehicleManager()     const { return m_vehicleManager.get(); }
    FlightLogger      *flightLogger()       const { return m_flightLogger.get(); }

    void initialize();

signals:
    void initialized();

private:
    static Application *s_instance;

    std::unique_ptr<AppSettings>       m_settings;
    std::unique_ptr<ConnectionManager> m_connectionManager;
    std::unique_ptr<MAVLinkManager>    m_mavlinkManager;
    std::unique_ptr<VehicleManager>    m_vehicleManager;
    std::unique_ptr<FlightLogger>      m_flightLogger;
};

} // namespace IndigenousGCS
