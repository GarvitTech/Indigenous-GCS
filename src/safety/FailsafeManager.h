#pragma once
#include <QObject>
#include <QString>

namespace IndigenousGCS {

class ParameterManager;

// Provides a typed interface to configure common failsafe parameters.
// Actual values are sent via ParameterManager → MAVLink PARAM_SET.
class FailsafeManager : public QObject
{
    Q_OBJECT
public:
    explicit FailsafeManager(ParameterManager *params, QObject *parent = nullptr);

    // Battery failsafe threshold (voltage, volts)
    Q_INVOKABLE void setBatteryFailsafeVoltage(uint8_t targetSys, uint8_t targetComp, float volts);
    // RC loss failsafe action (0=disabled, 1=RTL, 2=Land)
    Q_INVOKABLE void setRCLossAction(uint8_t targetSys, uint8_t targetComp, int action);
    // GCS loss failsafe action
    Q_INVOKABLE void setGCSLossAction(uint8_t targetSys, uint8_t targetComp, int action);

private:
    ParameterManager *m_params;
};

} // namespace IndigenousGCS
