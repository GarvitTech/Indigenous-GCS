#include "VehicleManager.h"
#include "Vehicle.h"
#include "mavlink/MAVLinkManager.h"
#include <QLoggingCategory>
#include <algorithm>

Q_LOGGING_CATEGORY(lcVehicleMgr, "igcs.vehiclemgr")

namespace IndigenousGCS {

VehicleManager::VehicleManager(MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent), m_mavlink(mavlink)
{
    connect(mavlink, &MAVLinkManager::vehicleDetected,
            this, &VehicleManager::onVehicleDetected);
    connect(mavlink, &MAVLinkManager::vehicleLost,
            this, &VehicleManager::onVehicleLost);
    connect(mavlink, &MAVLinkManager::vehicleSourceChanged,
            this, &VehicleManager::onVehicleSourceChanged);
    connect(mavlink, &MAVLinkManager::messageReceived,
            this, &VehicleManager::onMessageReceived);
}

void VehicleManager::onVehicleDetected(uint8_t sysId, uint8_t compId, bool simulated)
{
    if (m_vehicles.count(sysId)) return;

    auto vehicle = std::make_unique<Vehicle>(sysId, compId, m_mavlink, simulated, this);
    vehicle->setConnected(true);

    connect(vehicle.get(), &Vehicle::telemetryUpdated,
            this, &VehicleManager::telemetryUpdated);

    Vehicle *raw = vehicle.get();
    m_vehicles.emplace(sysId, std::move(vehicle));

    if (!m_activeVehicle || (m_activeVehicle->simulated() && !simulated)) {
        m_activeVehicle = raw;
        emit activeVehicleChanged(m_activeVehicle);
    }

    emit vehicleCountChanged();
    qCInfo(lcVehicleMgr) << "Vehicle added sysId=" << sysId;
}

void VehicleManager::onVehicleLost(uint8_t sysId)
{
    if (!m_vehicles.count(sysId)) return;

    if (m_activeVehicle && m_activeVehicle->sysId() == sysId) {
        m_activeVehicle = nullptr;
        emit activeVehicleChanged(nullptr);
    }

    m_vehicles.erase(sysId);
    emit vehicleCountChanged();
    qCWarning(lcVehicleMgr) << "Vehicle removed sysId=" << sysId;

    if (!m_activeVehicle && !m_vehicles.empty()) {
        auto real = std::find_if(m_vehicles.begin(), m_vehicles.end(),
                                 [](const auto &entry) { return !entry.second->simulated(); });
        m_activeVehicle = real != m_vehicles.end()
                ? real->second.get() : m_vehicles.begin()->second.get();
        emit activeVehicleChanged(m_activeVehicle);
    }
}

void VehicleManager::onVehicleSourceChanged(uint8_t sysId, bool simulated)
{
    auto it = m_vehicles.find(sysId);
    if (it == m_vehicles.end()) return;

    it->second->setSimulated(simulated);
    if (m_activeVehicle == it->second.get() && simulated) {
        auto real = std::find_if(m_vehicles.begin(), m_vehicles.end(),
                                 [](const auto &entry) { return !entry.second->simulated(); });
        if (real != m_vehicles.end()) {
            m_activeVehicle = real->second.get();
            emit activeVehicleChanged(m_activeVehicle);
        }
    } else if ((!m_activeVehicle || m_activeVehicle->simulated()) && !simulated) {
        m_activeVehicle = it->second.get();
        emit activeVehicleChanged(m_activeVehicle);
    }
}

void VehicleManager::onMessageReceived(const mavlink_message_t &msg)
{
    auto it = m_vehicles.find(msg.sysid);
    if (it != m_vehicles.end())
        it->second->handleMessage(msg);
}

} // namespace IndigenousGCS
