#pragma once
#include <QtGlobal>

namespace IndigenousGCS {

struct GeoCoordinate {
    double latitude  = 0.0;
    double longitude = 0.0;
    double altitude  = 0.0;
};

namespace GeoUtils {

/**
 * Pi, defined here rather than relying on M_PI.
 *
 * M_PI is a POSIX extension, not standard C++. glibc and libc++ expose it via
 * <cmath>, but MSVC only defines it when _USE_MATH_DEFINES is set before the
 * include. Using a project constant keeps every platform identical and avoids
 * the Windows build failure: error C2065: 'M_PI': undeclared identifier.
 */
inline constexpr double kPi = 3.14159265358979323846;

/** Degrees to radians. */
inline constexpr double kDegToRad = kPi / 180.0;

/** Radians to degrees. */
inline constexpr double kRadToDeg = 180.0 / kPi;

// Returns distance in metres between two WGS-84 coordinates (Haversine).
double distanceBetween(const GeoCoordinate &from, const GeoCoordinate &to);

// Returns initial bearing in degrees [0, 360) from 'from' to 'to'.
double bearingBetween(const GeoCoordinate &from, const GeoCoordinate &to);

// Returns the coordinate reached by travelling 'distanceMetres' at 'bearingDeg' from 'origin'.
GeoCoordinate destinationCoordinate(const GeoCoordinate &origin,
                                    double distanceMetres,
                                    double bearingDeg);

// Altitude difference in metres (to.altitude - from.altitude).
double altitudeDifference(const GeoCoordinate &from, const GeoCoordinate &to);

// Validate that a coordinate has plausible values.
bool isValid(const GeoCoordinate &coord);

} // namespace GeoUtils
} // namespace IndigenousGCS
