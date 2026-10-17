#pragma once
#include <QObject>
#include <unordered_map>
#include <memory>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"
#include "Vehicle.h"

namespace IndigenousGCS {

class MAVLinkManager;

class VehicleManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Vehicle* activeVehicle READ activeVehicle NOTIFY activeVehicleChanged)
    Q_PROPERTY(int      vehicleCount  READ vehicleCount  NOTIFY vehicleCountChanged)

public:
    explicit VehicleManager(MAVLinkManager *mavlink, QObject *parent = nullptr);

    Vehicle *activeVehicle() const { return m_activeVehicle; }
    int      vehicleCount()  const { return static_cast<int>(m_vehicles.size()); }

signals:
    void activeVehicleChanged(Vehicle *vehicle);
    void vehicleCountChanged();
    void telemetryUpdated();

public slots:
    void onVehicleDetected(uint8_t sysId, uint8_t compId, bool simulated);
    void onVehicleLost(uint8_t sysId);
    void onMessageReceived(const mavlink_message_t &msg);
    void onVehicleSourceChanged(uint8_t sysId, bool simulated);

private:
    MAVLinkManager                           *m_mavlink;
    std::unordered_map<uint8_t, std::unique_ptr<Vehicle>>  m_vehicles;
    Vehicle                                  *m_activeVehicle = nullptr;
};

} // namespace IndigenousGCS
