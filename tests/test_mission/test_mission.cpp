#include <QtTest>
#include "mission/Mission.h"
#include "mission/Waypoint.h"
#include "mission/MissionSerializer.h"
#include <QTemporaryFile>

using namespace IndigenousGCS;

class TestMission : public QObject
{
    Q_OBJECT

private slots:
    void testAddWaypoint() {
        Mission m;
        m.addWaypoint(28.6, 77.2, 10.0f);
        QCOMPARE(m.count(), 1);
        QCOMPARE(m.waypoints()[0].latitude,  28.6);
        QCOMPARE(m.waypoints()[0].longitude, 77.2);
        QCOMPARE(m.waypoints()[0].altitude,  10.0f);
    }

    void testRemoveWaypoint() {
        Mission m;
        m.addWaypoint(1.0, 1.0, 10.0f);
        m.addWaypoint(2.0, 2.0, 20.0f);
        m.removeWaypoint(0);
        QCOMPARE(m.count(), 1);
        QCOMPARE(m.waypoints()[0].latitude, 2.0);
        QCOMPARE(m.waypoints()[0].seq, (uint16_t)0);
    }

    void testMoveWaypoint() {
        Mission m;
        m.addWaypoint(1.0, 1.0, 10.0f);
        m.addWaypoint(2.0, 2.0, 20.0f);
        m.addWaypoint(3.0, 3.0, 30.0f);
        m.moveWaypoint(0, 2);
        QCOMPARE(m.waypoints()[0].latitude, 2.0);
        QCOMPARE(m.waypoints()[2].latitude, 1.0);
    }

    void testValidateEmpty() {
        Mission m;
        QStringList errors = m.validate();
        QVERIFY(!errors.isEmpty());
    }

    void testValidateValid() {
        Mission m;
        m.addWaypoint(28.6, 77.2, 10.0f);
        m.addWaypoint(28.7, 77.3, 15.0f);
        QStringList errors = m.validate();
        QVERIFY(errors.isEmpty());
    }

    void testWaypointToMavlink() {
        Waypoint wp;
        wp.seq       = 3;
        wp.latitude  = 28.6139;
        wp.longitude = 77.2090;
        wp.altitude  = 50.0f;
        wp.command   = MAV_CMD_NAV_WAYPOINT;

        mavlink_mission_item_int_t item = wp.toMavlinkItem();
        QCOMPARE(item.seq, (uint16_t)3);
        QCOMPARE(item.x,   (int32_t)(28.6139 * 1e7));
        QCOMPARE(item.y,   (int32_t)(77.2090 * 1e7));
        QCOMPARE(item.z,   50.0f);
    }

    void testWaypointFromMavlink() {
        mavlink_mission_item_int_t item{};
        item.seq     = 1;
        item.x       = (int32_t)(28.6 * 1e7);
        item.y       = (int32_t)(77.2 * 1e7);
        item.z       = 20.0f;
        item.command = MAV_CMD_NAV_WAYPOINT;
        item.frame   = MAV_FRAME_GLOBAL_RELATIVE_ALT;

        Waypoint wp = Waypoint::fromMavlinkItem(item);
        QCOMPARE(wp.seq, (uint16_t)1);
        QVERIFY(qAbs(wp.latitude  - 28.6) < 0.0001);
        QVERIFY(qAbs(wp.longitude - 77.2) < 0.0001);
        QCOMPARE(wp.altitude, 20.0f);
    }

    void testSerializeRoundTrip() {
        Mission m;
        m.setName("Test Mission");
        m.addWaypoint(28.6, 77.2, 10.0f);
        m.addWaypoint(28.7, 77.3, 20.0f);

        QTemporaryFile f;
        f.open(); f.close();
        QVERIFY(MissionSerializer::saveToFile(m, f.fileName()));

        Mission m2;
        QVERIFY(MissionSerializer::loadFromFile(m2, f.fileName()));
        QCOMPARE(m2.name(),  QString("Test Mission"));
        QCOMPARE(m2.count(), 2);
        QVERIFY(qAbs(m2.waypoints()[0].latitude  - 28.6) < 0.000001);
        QVERIFY(qAbs(m2.waypoints()[1].longitude - 77.3) < 0.000001);
    }
};

QTEST_MAIN(TestMission)
#include "test_mission.moc"
