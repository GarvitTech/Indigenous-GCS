#include "GeoUtils.h"
#include <cmath>

namespace IndigenousGCS::GeoUtils {

static constexpr double kEarthRadiusM = 6371000.0;
static constexpr double kDeg2Rad      = kDegToRad;
static constexpr double kRad2Deg      = kRadToDeg;

double distanceBetween(const GeoCoordinate &from, const GeoCoordinate &to)
{
    const double lat1 = from.latitude  * kDeg2Rad;
    const double lat2 = to.latitude    * kDeg2Rad;
    const double dLat = (to.latitude  - from.latitude)  * kDeg2Rad;
    const double dLon = (to.longitude - from.longitude) * kDeg2Rad;

    const double a = std::sin(dLat / 2) * std::sin(dLat / 2)
                   + std::cos(lat1) * std::cos(lat2)
                   * std::sin(dLon / 2) * std::sin(dLon / 2);
    return kEarthRadiusM * 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));
}

double bearingBetween(const GeoCoordinate &from, const GeoCoordinate &to)
{
    const double lat1 = from.latitude  * kDeg2Rad;
    const double lat2 = to.latitude    * kDeg2Rad;
    const double dLon = (to.longitude - from.longitude) * kDeg2Rad;

    const double y = std::sin(dLon) * std::cos(lat2);
    const double x = std::cos(lat1) * std::sin(lat2)
                   - std::sin(lat1) * std::cos(lat2) * std::cos(dLon);

    double bearing = std::atan2(y, x) * kRad2Deg;
    return std::fmod(bearing + 360.0, 360.0);
}

GeoCoordinate destinationCoordinate(const GeoCoordinate &origin,
                                    double distanceMetres,
                                    double bearingDeg)
{
    const double d     = distanceMetres / kEarthRadiusM;
    const double brng  = bearingDeg * kDeg2Rad;
    const double lat1  = origin.latitude  * kDeg2Rad;
    const double lon1  = origin.longitude * kDeg2Rad;

    const double lat2 = std::asin(std::sin(lat1) * std::cos(d)
                                + std::cos(lat1) * std::sin(d) * std::cos(brng));
    const double lon2 = lon1 + std::atan2(std::sin(brng) * std::sin(d) * std::cos(lat1),
                                          std::cos(d) - std::sin(lat1) * std::sin(lat2));

    return { lat2 * kRad2Deg, lon2 * kRad2Deg, origin.altitude };
}

double altitudeDifference(const GeoCoordinate &from, const GeoCoordinate &to)
{
    return to.altitude - from.altitude;
}

bool isValid(const GeoCoordinate &coord)
{
    return coord.latitude  >= -90.0  && coord.latitude  <= 90.0
        && coord.longitude >= -180.0 && coord.longitude <= 180.0;
}

} // namespace IndigenousGCS::GeoUtils
