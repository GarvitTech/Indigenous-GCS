#include <QtTest>
#include "parameters/Parameter.h"

using namespace IndigenousGCS;

class TestParameters : public QObject
{
    Q_OBJECT

private slots:
    void testDisplayValueFloat() {
        Parameter p;
        p.name  = "ATC_RAT_RLL_P";
        p.value = 0.135f;
        p.type  = MAV_PARAM_TYPE_REAL32;
        QVERIFY(qAbs(p.displayValue().toDouble() - 0.135) < 0.0001);
    }

    void testDisplayValueInt32() {
        Parameter p;
        p.name  = "SCHED_LOOP_RATE";
        p.value = 400.0f;
        p.type  = MAV_PARAM_TYPE_INT32;
        QCOMPARE(p.displayValue().toInt(), 400);
    }

    void testDisplayValueUint8() {
        Parameter p;
        p.value = 1.0f;
        p.type  = MAV_PARAM_TYPE_UINT8;
        QCOMPARE(p.displayValue().toUInt(), (uint)1);
    }

    void testTypeName() {
        Parameter p;
        p.type = MAV_PARAM_TYPE_REAL32; QCOMPARE(p.typeName(), QString("float"));
        p.type = MAV_PARAM_TYPE_INT32;  QCOMPARE(p.typeName(), QString("int32"));
        p.type = MAV_PARAM_TYPE_UINT8;  QCOMPARE(p.typeName(), QString("uint8"));
    }

    void testNegativeValue() {
        Parameter p;
        p.value = -1.5f;
        p.type  = MAV_PARAM_TYPE_REAL32;
        QVERIFY(qAbs(p.displayValue().toDouble() - (-1.5)) < 0.0001);
    }
};

QTEST_MAIN(TestParameters)
#include "test_parameters.moc"
