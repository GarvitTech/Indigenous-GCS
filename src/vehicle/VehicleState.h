#pragma once
#include <QString>
#include <QDateTime>
#include <QReadWriteLock>

namespace IndigenousGCS {

struct VehicleState {
    mutable QReadWriteLock lock;

    void copyFrom(const VehicleState &other) {
        // Lock both to ensure a consistent snapshot
        QWriteLocker writeLock(&this->lock);
        QReadLocker readLock(&other.lock);

        sysId       = other.sysId;
        compId      = other.compId;
        autopilot   = other.autopilot;
        vehicleType = other.vehicleType;
        firmwareVersion = other.firmwareVersion;
        armed       = other.armed;
        baseMode    = other.baseMode;
        customMode  = other.customMode;
        flightMode  = other.flightMode;
        systemStatus = other.systemStatus;
        roll  = other.roll;
        pitch = other.pitch;
        yaw   = other.yaw;
        rollSpeed  = other.rollSpeed;
        pitchSpeed = other.pitchSpeed;
        yawSpeed   = other.yawSpeed;
        gpsFixType  = other.gpsFixType;
        gpsSatCount = other.gpsSatCount;
        latitude    = other.latitude;
        longitude   = other.longitude;
        altitudeMSL = other.altitudeMSL;
        altitudeRel = other.altitudeRel;
        hdop        = other.hdop;
        vdop        = other.vdop;
        groundSpeed = other.groundSpeed;
        airSpeed    = other.airSpeed;
        climbRate   = other.climbRate;
        heading     = other.heading;
        batteryVoltage    = other.batteryVoltage;
        batteryCurrent    = other.batteryCurrent;
        batteryRemaining  = other.batteryRemaining;
        sensorsPresentBitmask  = other.sensorsPresentBitmask;
        sensorsEnabledBitmask  = other.sensorsEnabledBitmask;
        sensorsHealthBitmask   = other.sensorsHealthBitmask;
        cpuLoad                = other.cpuLoad;
        rcAvailable = other.rcAvailable;
        rcRssi      = other.rcRssi;
        homeSet      = other.homeSet;
        homeLat      = other.homeLat;
        homeLon      = other.homeLon;
        homeAlt      = other.homeAlt;
        lastHeartbeat = other.lastHeartbeat;
        lastUpdate    = other.lastUpdate;
    }

    // Identity
    uint8_t  sysId       = 0;
    uint8_t  compId      = 0;
    uint8_t  autopilot   = 0;
    uint8_t  vehicleType = 0;
    QString  firmwareVersion;

    // Arm / Mode
    bool     armed       = false;
    uint8_t  baseMode    = 0;
    uint32_t customMode  = 0;
    QString  flightMode;
    uint8_t  systemStatus = 0;

    // Attitude (radians internally)
    float roll  = 0.0f;
    float pitch = 0.0f;
    float yaw   = 0.0f;
    float rollSpeed  = 0.0f;
    float pitchSpeed = 0.0f;
    float yawSpeed   = 0.0f;

    // GPS
    uint8_t  gpsFixType  = 0;
    uint8_t  gpsSatCount = 0;
    double   latitude    = 0.0;
    double   longitude   = 0.0;
    double   altitudeMSL = 0.0;
    double   altitudeRel = 0.0;
    float    hdop        = 99.9f;
    float    vdop        = 99.9f;

    // Velocity
    float groundSpeed = 0.0f;
    float airSpeed    = 0.0f;
    float climbRate   = 0.0f;
    float heading     = 0.0f;   // degrees

    // Battery
    float batteryVoltage    = 0.0f;
    float batteryCurrent    = 0.0f;
    int   batteryRemaining  = -1;  // percent, -1 = unknown

    // System
    uint16_t sensorsPresentBitmask  = 0;
    uint16_t sensorsEnabledBitmask  = 0;
    uint16_t sensorsHealthBitmask   = 0;
    uint16_t cpuLoad                = 0;  // per mille

    // RC
    bool    rcAvailable = false;
    uint8_t rcRssi      = 0;

    // Home
    bool   homeSet      = false;
    double homeLat      = 0.0;
    double homeLon      = 0.0;
    double homeAlt      = 0.0;

    QDateTime lastHeartbeat;
    QDateTime lastUpdate;
};

} // namespace IndigenousGCS
