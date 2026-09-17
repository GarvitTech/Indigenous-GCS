#pragma once
#include <QtGlobal>

namespace IndigenousGCS {

struct GeoCoordinate {
    double latitude  = 0.0;
    double longitude = 0.0;
    double altitude  = 0.0;
};

namespace GeoUtils {

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
