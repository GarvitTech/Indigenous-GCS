#include <QtTest>
#include "vehicle/FlightModeManager.h"
#include "vehicle/VehicleState.h"

using namespace IndigenousGCS;

class TestVehicle : public QObject
{
    Q_OBJECT

private slots:
    void testFlightModeMapping() {
        FlightModeManager mgr;
        QCOMPARE(mgr.modeNameFromCustom(0),  QString("Stabilize"));
        QCOMPARE(mgr.modeNameFromCustom(2),  QString("Alt Hold"));
        QCOMPARE(mgr.modeNameFromCustom(5),  QString("Loiter"));
        QCOMPARE(mgr.modeNameFromCustom(6),  QString("RTL"));
        QCOMPARE(mgr.modeNameFromCustom(9),  QString("Land"));
        QCOMPARE(mgr.modeNameFromCustom(16), QString("PosHold"));
    }

    void testFlightModeReverseMapping() {
        FlightModeManager mgr;
        QCOMPARE(mgr.customModeFromName("Stabilize"), (uint32_t)0);
        QCOMPARE(mgr.customModeFromName("RTL"),       (uint32_t)6);
        QCOMPARE(mgr.customModeFromName("Land"),      (uint32_t)9);
    }

    void testUnknownMode() {
        FlightModeManager mgr;
        QString name = mgr.modeNameFromCustom(99);
        QVERIFY(name.contains("99"));
    }

    void testAvailableModes() {
        FlightModeManager mgr;
        QStringList modes = mgr.availableModes();
        QVERIFY(modes.contains("Stabilize"));
        QVERIFY(modes.contains("RTL"));
        QVERIFY(modes.contains("Land"));
        QVERIFY(!modes.isEmpty());
    }

    void testBaseModeArmed() {
        FlightModeManager mgr;
        uint8_t base = mgr.baseModeForCustom(0, true);
        QVERIFY(base & 0x80); // MAV_MODE_FLAG_SAFETY_ARMED
    }

    void testBaseModeDisarmed() {
        FlightModeManager mgr;
        uint8_t base = mgr.baseModeForCustom(0, false);
        QVERIFY(!(base & 0x80));
    }

    void testVehicleStateDefaults() {
        VehicleState s;
        QCOMPARE(s.armed,       false);
        QCOMPARE(s.latitude,    0.0);
        QCOMPARE(s.longitude,   0.0);
        QCOMPARE(s.gpsFixType,  (uint8_t)0);
        QCOMPARE(s.batteryRemaining, -1);
    }
};

QTEST_MAIN(TestVehicle)
#include "test_vehicle.moc"
