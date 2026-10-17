#include "Telemetry.h"

namespace IndigenousGCS {

Telemetry::Telemetry(QObject *parent) : QObject(parent) {}

void Telemetry::update(const VehicleState &state)
{
    const bool attChg  = (state.roll  != m_state.roll  ||
                               state.pitch != m_state.pitch ||
                               state.yaw   != m_state.yaw   ||
                               state.heading != m_state.heading);
    const bool posChg  = (state.latitude    != m_state.latitude  ||
                               state.longitude   != m_state.longitude ||
                               state.altitudeMSL != m_state.altitudeMSL ||
                               state.altitudeRel != m_state.altitudeRel);
    const bool spdChg  = (state.groundSpeed != m_state.groundSpeed ||
                               state.airSpeed    != m_state.airSpeed    ||
                               state.climbRate   != m_state.climbRate);
    const bool gpsChg  = (state.gpsFixType  != m_state.gpsFixType  ||
                               state.gpsSatCount != m_state.gpsSatCount ||
                               state.hdop        != m_state.hdop);
    const bool batChg  = (state.batteryVoltage   != m_state.batteryVoltage  ||
                               state.batteryCurrent   != m_state.batteryCurrent  ||
                               state.batteryRemaining != m_state.batteryRemaining);
    const bool stChg   = (state.armed      != m_state.armed      ||
                               state.flightMode != m_state.flightMode ||
                               state.cpuLoad    != m_state.cpuLoad);
    const bool rcChg   = (state.rcRssi != m_state.rcRssi);

    m_state.copyFrom(state);

    if (attChg) emit attitudeChanged();
    if (posChg) emit positionChanged();
    if (spdChg) emit speedChanged();
    if (gpsChg) emit gpsChanged();
    if (batChg) emit batteryChanged();
    if (stChg)  emit stateChanged();
    if (rcChg)  emit rcChanged();
}

} // namespace IndigenousGCS
