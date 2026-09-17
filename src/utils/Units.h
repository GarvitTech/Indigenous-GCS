#pragma once
#include <QString>

namespace IndigenousGCS::Units {

enum class System { Metric, Imperial };

// Length
double metersToFeet(double m);
double feetToMeters(double ft);

// Speed
double msToKmh(double ms);
double msToKnots(double ms);
double msToMph(double ms);

// Temperature
double celsiusToFahrenheit(double c);

// Formatted display strings (includes unit suffix)
QString formatAltitude(double metres, System sys);
QString formatSpeed(double ms, System sys);
QString formatDistance(double metres, System sys);
QString formatTemperature(double celsius, System sys);

} // namespace IndigenousGCS::Units
