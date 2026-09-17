#include "Application.h"
#include "AppSettings.h"
#include "communication/ConnectionManager.h"
#include "mavlink/MAVLinkManager.h"
#include "vehicle/VehicleManager.h"
#include "logging/FlightLogger.h"

namespace IndigenousGCS {

Application *Application::s_instance = nullptr;

Application::Application(QObject *parent) : QObject(parent)
{
    Q_ASSERT(!s_instance);
    s_instance = this;
}

Application::~Application()
{
    s_instance = nullptr;
}

Application *Application::instance()
{
    return s_instance;
}

void Application::initialize()
{
    m_settings           = std::make_unique<AppSettings>(this);
    m_connectionManager  = std::make_unique<ConnectionManager>(this);
    m_mavlinkManager     = std::make_unique<MAVLinkManager>(m_settings.get(), this);
    m_vehicleManager     = std::make_unique<VehicleManager>(m_mavlinkManager.get(), this);
    m_flightLogger       = std::make_unique<FlightLogger>(this);

    // Wire MAVLink bytes from connection to parser
    connect(m_connectionManager.get(), &ConnectionManager::bytesReceived,
            m_mavlinkManager.get(),    &MAVLinkManager::processBytes);

    // Wire MAVLink bytes to send via connection
    connect(m_mavlinkManager.get(),    &MAVLinkManager::bytesToSend,
            m_connectionManager.get(), &ConnectionManager::sendBytes);

    // Wire vehicle state updates to logger
    connect(m_vehicleManager.get(), &VehicleManager::telemetryUpdated,
            m_flightLogger.get(),   &FlightLogger::onTelemetryUpdated);

    emit initialized();
}

} // namespace IndigenousGCS
