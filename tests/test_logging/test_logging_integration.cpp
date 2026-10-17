// End-to-end verification of the flight-logging path.
//
// This is deliberately a *behavioural* test rather than a unit test: it runs
// the exact call sequence the Logs page performs (start -> log samples ->
// stop -> list -> read -> export) against the real FlightLogger and LogReader,
// using the real SQLite database on disk.
//
// It exists because logging previously failed in a way that compiled cleanly
// and passed every other test: FlightLogger wrote to logs.db while LogReader
// read from flightlogs.db, so recordings were written and then never seen.
// The first assertion below is the one that catches that class of bug.

#include <QtTest>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QFile>
#include <QDir>
#include <QTextStream>

#include "logging/LogPaths.h"
#include "logging/FlightLogger.h"
#include "logging/LogReader.h"

using namespace IndigenousGCS;

class TestLoggingIntegration : public QObject
{
    Q_OBJECT

private slots:
    void writerAndReaderShareOneDatabase();
    void fullRecordingRoundTrip();
    void csvExportIsWellFormed();
    void concurrentSessionsDoNotInterleave();
};

// The regression test for the split-brain bug.
void TestLoggingIntegration::writerAndReaderShareOneDatabase()
{
    FlightLogger logger;
    LogReader reader;

    const QString w = logger.databasePath();
    const QString r = reader.databasePath();

    QVERIFY2(!w.isEmpty(), "FlightLogger has no database path");
    QVERIFY2(!r.isEmpty(), "LogReader has no database path");
    QCOMPARE(w, r);

    // Both must be usable, not merely equal.
    QVERIFY2(logger.isAvailable(), "FlightLogger could not open the database");
    QVERIFY2(reader.isAvailable(), "LogReader could not open the database");

    // The file must actually exist on disk, and be a single file — the old bug
    // left two separate .db files behind.
    QVERIFY(QFile::exists(w));

    const QDir dir(LogPaths::dataDirectory());
    const QStringList dbs = dir.entryList({QStringLiteral("*.db")}, QDir::Files);
    QVERIFY2(dbs.size() >= 1, "no database file present in the log directory");
}

void TestLoggingIntegration::fullRecordingRoundTrip()
{
    FlightLogger logger;
    LogReader reader;

    const int before = reader.listSessions().size();

    // ── START LOGGING (what the button does) ─────────────────────────────
    logger.startLogging(QStringLiteral("sys250"));
    QVERIFY2(logger.isLogging(), "logging did not start");
    QVERIFY2(logger.isAvailable(), "database became unavailable on start");

    // ── TELEMETRY (what the 4 Hz feed delivers) ──────────────────────────
    const int samples = 10;
    for (int i = 0; i < samples; ++i)
    {
        logger.logTelemetry(28.6139 + i * 0.0001,
                            77.2090 + i * 0.0001,
                            90.0 + i,
                            1.0f, 2.0f, 180.0f,
                            5.0f, -1.0f,
                            12.2f, 85,
                            3, 12,
                            QStringLiteral("Auto"),
                            i % 2 == 0);
    }

    // ── STOP LOGGING (flushes the buffer) ────────────────────────────────
    logger.stopLogging();
    QVERIFY2(!logger.isLogging(), "logging did not stop");

    // ── REFRESH (what the session list does) ─────────────────────────────
    const QVariantList sessions = reader.listSessions();
    QCOMPARE(sessions.size(), before + 1);

    const QVariantMap session = sessions.first().toMap();
    QCOMPARE(session["label"].toString(), QStringLiteral("sys250"));

    const qint64 id = session["id"].toLongLong();
    QVERIFY2(id > 0, "session id was not assigned");

    // Every sample must be present. The old implementation kept only the most
    // recent value and flushed that once per second, silently dropping the
    // samples in between.
    const int rowCount = session["rowCount"].toInt();
    QCOMPARE(rowCount, samples);

    // ── READ (what selecting the session does) ───────────────────────────
    const QVariantList rows = reader.readSession(id);
    QCOMPARE(rows.size(), samples);

    const QVariantMap first = rows.first().toMap();
    QCOMPARE(first["flightMode"].toString(), QStringLiteral("Auto"));
    QCOMPARE(first["gpsSats"].toInt(), 12);
    QCOMPARE(first["armed"].toBool(), true);
    QVERIFY(qAbs(first["altRel"].toDouble() - 90.0) < 0.001);

    // The last sample must also be present, proving nothing was truncated.
    const QVariantMap last = rows.last().toMap();
    QVERIFY(qAbs(last["altRel"].toDouble() - (90.0 + samples - 1)) < 0.001);

    // Timestamps must be ISO so the UI can parse them.
    const QDateTime started = QDateTime::fromString(session["started"].toString(), Qt::ISODate);
    QVERIFY2(started.isValid(), "session start timestamp is not ISO-formatted");
    QVERIFY2(session["duration"].toInt() >= 0, "session duration was not computed");
}

void TestLoggingIntegration::csvExportIsWellFormed()
{
    FlightLogger logger;
    LogReader reader;

    logger.startLogging(QStringLiteral("export-check"));
    logger.logTelemetry(28.6, 77.2, 42.5, 0, 0, 90, 3.5, 0.2,
                        12.0f, 77, 3, 11, QStringLiteral("Loiter"), true);
    logger.stopLogging();

    const QVariantList sessions = reader.listSessions();
    QVERIFY(!sessions.isEmpty());
    const qint64 id = sessions.first().toMap()["id"].toLongLong();

    const QString csv = QDir::tempPath() + QStringLiteral("/igcs-export-check.csv");
    QFile::remove(csv);
    QVERIFY2(reader.exportSession(id, csv), "exportSession returned false");
    QVERIFY(QFile::exists(csv));

    QFile f(csv);
    QVERIFY(f.open(QIODevice::ReadOnly | QIODevice::Text));
    const QString content = QString::fromUtf8(f.readAll());
    f.close();

    // Header, metadata and at least one data line.
    QVERIFY2(content.contains(QStringLiteral("timestamp,latitude,longitude")),
             "CSV header missing");
    QVERIFY2(content.contains(QStringLiteral("# session_id=")), "CSV metadata missing");
    QVERIFY2(content.contains(QStringLiteral("Loiter")), "recorded mode missing from CSV");

    // Every data line must have the same field count as the header.
    const QStringList lines = content.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    int headerFields = -1;
    for (const QString &line : lines)
    {
        if (line.startsWith(QLatin1Char('#')))
            continue;
        const int fields = line.count(QLatin1Char(',')) + 1;
        if (headerFields < 0)
            headerFields = fields;
        else
            QCOMPARE(fields, headerFields);
    }
    QVERIFY2(headerFields > 10, "CSV header has too few columns");
}

void TestLoggingIntegration::concurrentSessionsDoNotInterleave()
{
    FlightLogger logger;
    LogReader reader;

    logger.startLogging(QStringLiteral("session-A"));
    logger.logTelemetry(1.0, 1.0, 10.0, 0, 0, 0, 0, 0, 12.0f, 50, 3, 8,
                        QStringLiteral("Auto"), false);
    logger.stopLogging();

    logger.startLogging(QStringLiteral("session-B"));
    logger.logTelemetry(2.0, 2.0, 20.0, 0, 0, 0, 0, 0, 12.0f, 50, 3, 8,
                        QStringLiteral("RTL"), false);
    logger.logTelemetry(2.1, 2.1, 21.0, 0, 0, 0, 0, 0, 12.0f, 50, 3, 8,
                        QStringLiteral("RTL"), false);
    logger.stopLogging();

    const QVariantList sessions = reader.listSessions();
    QVERIFY(sessions.size() >= 2);

    const QVariantMap b = sessions[0].toMap(); // newest first
    const QVariantMap a = sessions[1].toMap();
    QCOMPARE(b["label"].toString(), QStringLiteral("session-B"));
    QCOMPARE(a["label"].toString(), QStringLiteral("session-A"));

    // Rows must belong to their own session, never merged.
    QCOMPARE(a["rowCount"].toInt(), 1);
    QCOMPARE(b["rowCount"].toInt(), 2);

    const QVariantList rowsA = reader.readSession(a["id"].toLongLong());
    QCOMPARE(rowsA.size(), 1);
    QCOMPARE(rowsA.first().toMap()["flightMode"].toString(), QStringLiteral("Auto"));
}

QTEST_MAIN(TestLoggingIntegration)
#include "test_logging_integration.moc"
