#include "FailsafeManager.h"
#include "parameters/ParameterManager.h"

namespace IndigenousGCS {

FailsafeManager::FailsafeManager(ParameterManager *params, QObject *parent)
    : QObject(parent), m_params(params) {}

void FailsafeManager::setBatteryFailsafeVoltage(uint8_t targetSys, uint8_t targetComp, float volts)
{
    // ArduCopter parameter: FS_BATT_VOLTAGE
    m_params->setParameter(targetSys, targetComp, "FS_BATT_VOLTAGE", volts);
}

void FailsafeManager::setRCLossAction(uint8_t targetSys, uint8_t targetComp, int action)
{
    // ArduCopter parameter: FS_THR_ENABLE
    m_params->setParameter(targetSys, targetComp, "FS_THR_ENABLE", static_cast<float>(action));
}

void FailsafeManager::setGCSLossAction(uint8_t targetSys, uint8_t targetComp, int action)
{
    // ArduCopter parameter: FS_GCS_ENABLE
    m_params->setParameter(targetSys, targetComp, "FS_GCS_ENABLE", static_cast<float>(action));
}

} // namespace IndigenousGCS
