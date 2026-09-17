#include <QtTest>
#include "utils/GeoUtils.h"

using namespace IndigenousGCS;
using namespace IndigenousGCS::GeoUtils;

class TestGeo : public QObject
{
    Q_OBJECT

private slots:
    void testDistanceZero() {
        GeoCoordinate a{28.6139, 77.2090, 0};
        QCOMPARE(distanceBetween(a, a), 0.0);
    }

    void testDistanceKnown() {
        // Delhi to Mumbai ~1150 km
        GeoCoordinate delhi{28.6139, 77.2090, 0};
        GeoCoordinate mumbai{19.0760, 72.8777, 0};
        double d = distanceBetween(delhi, mumbai);
        QVERIFY(d > 1100000.0 && d < 1200000.0);
    }

    void testBearingNorth() {
        GeoCoordinate a{0.0, 0.0, 0};
        GeoCoordinate b{1.0, 0.0, 0};
        double bearing = bearingBetween(a, b);
        QVERIFY(qAbs(bearing - 0.0) < 1.0 || qAbs(bearing - 360.0) < 1.0);
    }

    void testBearingEast() {
        GeoCoordinate a{0.0, 0.0, 0};
        GeoCoordinate b{0.0, 1.0, 0};
        double bearing = bearingBetween(a, b);
        QVERIFY(qAbs(bearing - 90.0) < 1.0);
    }

    void testDestinationCoordinate() {
        GeoCoordinate origin{0.0, 0.0, 0};
        GeoCoordinate dest = destinationCoordinate(origin, 111320.0, 0.0); // ~1 degree north
        QVERIFY(qAbs(dest.latitude - 1.0) < 0.01);
        QVERIFY(qAbs(dest.longitude) < 0.01);
    }

    void testAltitudeDifference() {
        GeoCoordinate a{0, 0, 100};
        GeoCoordinate b{0, 0, 250};
        QCOMPARE(altitudeDifference(a, b), 150.0);
    }

    void testIsValid() {
        QVERIFY(isValid({28.6, 77.2, 0}));
        QVERIFY(!isValid({91.0, 0.0, 0}));
        QVERIFY(!isValid({0.0, 181.0, 0}));
        QVERIFY(!isValid({-91.0, 0.0, 0}));
    }

    void testRoundTrip() {
        GeoCoordinate origin{28.6139, 77.2090, 0};
        double bearing = 45.0;
        double dist    = 5000.0;
        GeoCoordinate dest = destinationCoordinate(origin, dist, bearing);
        double back = distanceBetween(origin, dest);
        QVERIFY(qAbs(back - dist) < 1.0);
    }
};

QTEST_MAIN(TestGeo)
#include "test_geo.moc"
