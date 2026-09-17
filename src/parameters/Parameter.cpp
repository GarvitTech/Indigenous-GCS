#include "Parameter.h"

namespace IndigenousGCS {

QVariant Parameter::displayValue() const
{
    switch (type) {
    case MAV_PARAM_TYPE_UINT8:  return static_cast<uint>(static_cast<uint8_t>(value));
    case MAV_PARAM_TYPE_INT8:   return static_cast<int>(static_cast<int8_t>(value));
    case MAV_PARAM_TYPE_UINT16: return static_cast<uint>(static_cast<uint16_t>(value));
    case MAV_PARAM_TYPE_INT16:  return static_cast<int>(static_cast<int16_t>(value));
    case MAV_PARAM_TYPE_UINT32: return static_cast<uint>(static_cast<uint32_t>(value));
    case MAV_PARAM_TYPE_INT32:  return static_cast<int>(static_cast<int32_t>(value));
    default:                    return static_cast<double>(value);
    }
}

QString Parameter::typeName() const
{
    switch (type) {
    case MAV_PARAM_TYPE_UINT8:  return "uint8";
    case MAV_PARAM_TYPE_INT8:   return "int8";
    case MAV_PARAM_TYPE_UINT16: return "uint16";
    case MAV_PARAM_TYPE_INT16:  return "int16";
    case MAV_PARAM_TYPE_UINT32: return "uint32";
    case MAV_PARAM_TYPE_INT32:  return "int32";
    case MAV_PARAM_TYPE_REAL32: return "float";
    case MAV_PARAM_TYPE_REAL64: return "double";
    default:                    return "unknown";
    }
}

} // namespace IndigenousGCS
