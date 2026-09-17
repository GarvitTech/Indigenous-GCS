#include "ParameterManager.h"
#include "mavlink/MAVLinkManager.h"
#include "mavlink/MAVLinkSender.h"
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcParam, "igcs.params")

namespace IndigenousGCS {

ParameterManager::ParameterManager(MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent), m_mavlink(mavlink) {}

void ParameterManager::requestAll(uint8_t targetSys, uint8_t targetComp)
{
    m_params.clear();
    m_totalCount = 0;
    m_loading    = true;
    emit loadingChanged();
    emit parametersChanged();
    m_mavlink->sender()->sendParamRequestList(targetSys, targetComp);
    qCInfo(lcParam) << "Requesting all parameters from sysId=" << targetSys;
}

void ParameterManager::setParameter(uint8_t targetSys, uint8_t targetComp,
                                     const QString &name, float value)
{
    MAV_PARAM_TYPE type = MAV_PARAM_TYPE_REAL32;
    if (m_params.contains(name))
        type = m_params[name].type;
    m_mavlink->sender()->sendParamSet(targetSys, targetComp, name, value, type);
    qCInfo(lcParam) << "Set param" << name << "=" << value;
}

QVariant ParameterManager::getParameter(const QString &name) const
{
    if (m_params.contains(name))
        return m_params[name].displayValue();
    return QVariant();
}

QStringList ParameterManager::parameterNames() const
{
    QStringList names = m_params.keys();
    names.sort();
    return names;
}

void ParameterManager::handleMessage(const mavlink_message_t &msg)
{
    if (msg.msgid == MAVLINK_MSG_ID_PARAM_VALUE)
        handleParamValue(msg);
}

void ParameterManager::handleParamValue(const mavlink_message_t &msg)
{
    mavlink_param_value_t pv;
    mavlink_msg_param_value_decode(&msg, &pv);

    char nameBuf[17] = {};
    strncpy(nameBuf, pv.param_id, 16);
    const QString name = QString::fromUtf8(nameBuf);

    Parameter &p = m_params[name];
    p.name  = name;
    p.value = pv.param_value;
    p.type  = static_cast<MAV_PARAM_TYPE>(pv.param_type);
    p.index = pv.param_index;
    p.count = pv.param_count;

    if (m_totalCount == 0 && pv.param_count > 0)
        m_totalCount = pv.param_count;

    if (m_loading && m_params.size() >= m_totalCount && m_totalCount > 0) {
        m_loading = false;
        emit loadingChanged();
        qCInfo(lcParam) << "All" << m_totalCount << "parameters received";
    }

    emit parametersChanged();
    emit parameterUpdated(name);
}

} // namespace IndigenousGCS
