#pragma once
#include <QString>
#include <QVariant>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

namespace IndigenousGCS {

struct Parameter {
    QString        name;
    float          value       = 0.0f;
    MAV_PARAM_TYPE type        = MAV_PARAM_TYPE_REAL32;
    int16_t        index       = -1;
    int16_t        count       = -1;
    bool           modified    = false;

    QVariant displayValue() const;
    QString  typeName()     const;
};

} // namespace IndigenousGCS
