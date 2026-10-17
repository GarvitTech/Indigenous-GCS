// Round-trip tests for flight logging.
//
// These exist because the logging feature was silently broken in a way no
// compile-time check could catch: FlightLogger wrote to "logs.db" while
// LogReader read from "flightlogs.db". Both classes worked perfectly in
// isolation, and the Logs page showed an empty list forever. These tests
// assert on the invariant that actually matters — a recorded session must be
// readable back through the same database path.

#include <QtTest>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QTemporaryDir>
#include <QFile>
#include <QDateTime>

// The classes under test.
#include "logging/LogPaths.h"
#include "logging/FlightLogger.h"
#include "logging/LogReader.h"

using namespace IndigenousGCS;

class TestLogging : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void writerAndReaderAgreeOnPath();
    void logDirectoryIsWritable();
    void startStopCreatesSession();
    void telemetryRowsRoundTrip();
    void stoppedSessionHasValidTimestamps();
    void exportWritesCsvWithHeaderAndRows();
    void clearRemovesEverything();

private:
    // Unique connection names per test so the shared default connection is
    // never reused across cases.
    QString m_connName;
};

void TestLogging::initTestCase()
{
    QVERIFY2(!LogPaths::databasePath().isEmpty(),
             "LogPaths::databasePath() returned empty — no writable app data location.");
}

// The regression test for the split-brain bug: one canonical path, used by both.
void TestLogging::writerAndReaderAgreeOnPath()
{
    FlightLogger writer;
    LogReader reader;

    QCOMPARE(writer.databasePath(), reader.databasePath());
    QVERIFY2(!writer.databasePath().isEmpty(), "logging database path is empty");
    QVERIFY2(writer.databasePath().endsWith("flightlogs.db"),
             "unexpected database filename");
    QVERIFY2(writer.isAvailable(), "FlightLogger could not open its database");
    QVERIFY2(reader.isAvailable(), "LogReader could not open its database");
}

void TestLogging::logDirectoryIsWritable()
{
    QVERIFY(LogPaths::isWritable());
    QVERIFY(QFile::exists(LogPaths::dataDirectory()));
}

void TestLogging::startStopCreatesSession()
{
    FlightLogger logger;
    LogReader reader;

    const int before = reader.listSessions().size();

    logger.startLogging(QStringLiteral("unit-test"));
    QVERIFY2(logger.isLogging(), "startLogging() did not enter the logging state");
    QVERIFY(logger.currentSessionRowCount() == 0);

    logger.stopLogging();
    QVERIFY2(!logger.isLogging(), "stopLogging() did not leave the logging state");

    const QVariantList after = reader.listSessions();
    QCOMPARE(after.size(), before + 1);

    // The newest session must be visible through the reader — this is the exact
    // thing that failed when the two classes used different files.
    const QVariantMap newest = after.first().toMap();
    QCOMPARE(newest["label"].toString(), QStringLiteral("unit-test"));
    QVERIFY2(newest["id"].toLongLong() > 0, "session has no id");
}

void TestLogging::telemetryRowsRoundTrip()
{
    FlightLogger logger;
    LogReader reader;

    const int before = reader.listSessions().size();

    logger.startLogging(QStringLiteral("telemetry-test"));

    // Feed three rows, then let the 1 s write timer flush them.
    for (int i = 0; i < 3; ++i)
    {
        logger.logTelemetry(28.6139 + i * 0.001, 77.2090 + i * 0.001, 100.0 + i,
                            1.5f, -2.0f, 270.0f, 10.0f + i, 0.5f,
                            12.4f, 90 - i, 3, 12,
                            QStringLiteral("Auto"), i > 0);
    }

    // Force a flush by stopping (stopLogging flushes the final row) — but first
    // give the timer a chance so we exercise the timer path too.
    QTest::qWait(1200);
    logger.stopLogging();

    QVERIFY2(logger.currentSessionRowCount() == 0,
             "row counter should reset after stopping");

    const QVariantList sessions = reader.listSessions();
    QCOMPARE(sessions.size(), before + 1);

    // listSessions() is ordered newest-first, so the session just written is
    // the first entry. Assert on its identity rather than assuming the
    // database was empty when this test started.
    const QVariantMap session = sessions.first().toMap();
    QCOMPARE(session["label"].toString(), QStringLiteral("telemetry-test"));
    const qint64 sessionId = session["id"].toLongLong();

    const QVariantList rows = reader.readSession(sessionId);
    QVERIFY2(!rows.isEmpty(), "no telemetry rows were persisted for the session");

    // Verify the values survived the round trip, not just the row count.
    // Rows come back in insertion order, so the first row is altitude 100.
    const QVariantMap first = rows.first().toMap();
    QVERIFY2(qAbs(first["altRel"].toDouble() - 100.0) < 0.001,
             qPrintable(QStringLiteral("expected altRel 100.0, got %1")
                        .arg(first["altRel"].toDouble())));
    QVERIFY(qAbs(first["lat"].toDouble() - 28.6139) < 0.0001);
    QCOMPARE(first["flightMode"].toString(), QStringLiteral("Auto"));
    QCOMPARE(first["gpsSats"].toInt(), 12);
}

void TestLogging::stoppedSessionHasValidTimestamps()
{
    FlightLogger logger;
    LogReader reader;

    logger.startLogging(QStringLiteral("timestamp-test"));
    QTest::qWait(1100); // ensure a non-zero duration is possible
    logger.stopLogging();

    const QVariantList sessions = reader.listSessions();
    QVERIFY(!sessions.isEmpty());
    const QVariantMap s = sessions.first().toMap();

    // Both timestamps must parse as ISO. They were previously written in two
    // different formats, which made every duration read as zero.
    const QDateTime started = QDateTime::fromString(s["started"].toString(), Qt::ISODate);
    const QDateTime stopped = QDateTime::fromString(s["stopped"].toString(), Qt::ISODate);
    QVERIFY2(started.isValid(), "session start is not a valid ISO timestamp");
    QVERIFY2(stopped.isValid(), "session stop is not a valid ISO timestamp");
    QVERIFY2(stopped >= started, "session stopped before it started");
    QVERIFY2(s["duration"].toInt() >= 0, "duration was not computed");
}

void TestLogging::exportWritesCsvWithHeaderAndRows()
{
    FlightLogger logger;
    LogReader reader;

    logger.startLogging(QStringLiteral("export-test"));
    logger.logTelemetry(28.6, 77.2, 50.0, 0.0f, 0.0f, 90.0f, 5.0f, 0.0f,
                        12.0f, 80, 3, 10, QStringLiteral("Loiter"), true);
    QTest::qWait(1200);
    logger.stopLogging();

    const QVariantList sessions = reader.listSessions();
    QVERIFY(!sessions.isEmpty());
    const qint64 sessionId = sessions.first().toMap()["id"].toLongLong();

    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString csv = dir.filePath(QStringLiteral("out.csv"));

    QVERIFY2(reader.exportSession(sessionId, csv), "exportSession() returned false");
    QVERIFY(QFile::exists(csv));

    QFile f(csv);
    QVERIFY(f.open(QIODevice::ReadOnly | QIODevice::Text));
    const QString content = QString::fromUtf8(f.readAll());

    QVERIFY2(content.contains(QStringLiteral("timestamp,latitude,longitude")),
             "CSV header is missing");
    QVERIFY2(content.contains(QStringLiteral("Loiter")),
             "exported CSV does not contain the recorded flight mode");
    QVERIFY2(content.contains(QStringLiteral("# rows=")),
             "exported CSV does not report its row count");
}

void TestLogging::clearRemovesEverything()
{
    FlightLogger logger;
    LogReader reader;

    logger.startLogging(QStringLiteral("clear-test"));
    logger.logTelemetry(1.0, 2.0, 3.0, 0, 0, 0, 0, 0, 12.0f, 50, 3, 8,
                        QStringLiteral("Manual"), false);
    QTest::qWait(1200);
    logger.stopLogging();

    QVERIFY(reader.clearSessions());
    QVERIFY2(reader.listSessions().isEmpty(), "sessions remain after clearSessions()");
}

QTEST_MAIN(TestLogging)
#include "test_logging.moc"
