#include "Units.h"
#include <cmath>

namespace IndigenousGCS::Units {

double metersToFeet(double m)   { return m * 3.28084; }
double feetToMeters(double ft)  { return ft / 3.28084; }
double msToKmh(double ms)       { return ms * 3.6; }
double msToKnots(double ms)     { return ms * 1.94384; }
double msToMph(double ms)       { return ms * 2.23694; }
double celsiusToFahrenheit(double c) { return c * 9.0 / 5.0 + 32.0; }

QString formatAltitude(double metres, System sys)
{
    if (sys == System::Imperial)
        return QString::number(metersToFeet(metres), 'f', 1) + " ft";
    return QString::number(metres, 'f', 1) + " m";
}

QString formatSpeed(double ms, System sys)
{
    if (sys == System::Imperial)
        return QString::number(msToMph(ms), 'f', 1) + " mph";
    return QString::number(msToKmh(ms), 'f', 1) + " km/h";
}

QString formatDistance(double metres, System sys)
{
    if (sys == System::Imperial) {
        double feet = metersToFeet(metres);
        if (feet >= 5280.0)
            return QString::number(feet / 5280.0, 'f', 2) + " mi";
        return QString::number(feet, 'f', 0) + " ft";
    }
    if (metres >= 1000.0)
        return QString::number(metres / 1000.0, 'f', 2) + " km";
    return QString::number(metres, 'f', 0) + " m";
}

QString formatTemperature(double celsius, System sys)
{
    if (sys == System::Imperial)
        return QString::number(celsiusToFahrenheit(celsius), 'f', 1) + " °F";
    return QString::number(celsius, 'f', 1) + " °C";
}

} // namespace IndigenousGCS::Units
