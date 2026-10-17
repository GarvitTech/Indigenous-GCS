// Tests for the bundled user guide resource and the IP location lookup.
//
// These guard two things that are easy to break silently:
//   1. resources/docs/guide.html is still registered in CMake, so the Settings
//      page's "OPEN USER GUIDE" button cannot end up pointing at nothing.
//   2. The guide still contains the copy-paste install commands for both
//      platforms, since that is the whole reason it exists.

#include <QtTest>
#include <QDir>
#include <QFile>
#include <QTemporaryFile>

class TestGuide : public QObject
{
    Q_OBJECT

private slots:
    void guideResourceIsBundled();
    void guideExtractsToDisk();
    void guideContainsBothPlatformCommands();
    void guideContainsCopyButtons();
    void guideMatchesApplicationPalette();
};

void TestGuide::guideResourceIsBundled()
{
    QFile f(QStringLiteral(":/docs/guide.html"));
    QVERIFY2(f.exists(), "The guide resource :/docs/guide.html is missing from the build. "
                         "Check the qt_add_resources(user_guide ...) block in CMakeLists.txt.");
    QVERIFY(f.open(QIODevice::ReadOnly));
    QVERIFY(f.size() > 5000);   // a truncated/empty resource is also a failure
}

void TestGuide::guideExtractsToDisk()
{
    // Mirror AppSettings::guideFilePath(): browsers cannot read qrc:/ URLs, so
    // the resource must be extractable to a real filesystem path.
    QFile in(QStringLiteral(":/docs/guide.html"));
    QVERIFY(in.open(QIODevice::ReadOnly));
    const QByteArray html = in.readAll();

    QTemporaryFile out(QDir::tempPath() + QStringLiteral("/igcs-guide-test-XXXXXX.html"));
    out.setAutoRemove(true);
    QVERIFY(out.open());
    QCOMPARE(out.write(html), static_cast<qint64>(html.size()));
    out.flush();

    QFile verify(out.fileName());
    QVERIFY(verify.open(QIODevice::ReadOnly));
    QCOMPARE(verify.size(), static_cast<qint64>(html.size()));
}

void TestGuide::guideContainsBothPlatformCommands()
{
    QFile f(QStringLiteral(":/docs/guide.html"));
    QVERIFY(f.open(QIODevice::ReadOnly));
    const QString html = QString::fromUtf8(f.readAll());

    // macOS path: Homebrew toolchain + DMG packaging.
    QVERIFY2(html.contains(QStringLiteral("brew install qt")),
             "macOS install commands are missing from the guide");
    QVERIFY2(html.contains(QStringLiteral("cmake -S . -B build")),
             "the CMake configure command is missing from the guide");

    // Windows path: winget toolchain + windeployqt + installer.
    QVERIFY2(html.contains(QStringLiteral("winget install")),
             "Windows install commands are missing from the guide");
    QVERIFY2(html.contains(QStringLiteral("windeployqt")),
             "the Qt deployment step is missing from the guide");

    // Both platforms must place the finished app on the Desktop, which is the
    // behaviour the user explicitly asked for.
    QVERIFY2(html.contains(QStringLiteral("~/Desktop/IndigenousGCS.app")),
             "macOS does not copy the app to the Desktop");
    QVERIFY2(html.contains(QStringLiteral("Desktop\\IndigenousGCS-app")),
             "Windows does not copy the app to the Desktop");
}

void TestGuide::guideContainsCopyButtons()
{
    QFile f(QStringLiteral(":/docs/guide.html"));
    QVERIFY(f.open(QIODevice::ReadOnly));
    const QString html = QString::fromUtf8(f.readAll());

    // Every command block is meant to be copy-pasteable in one click.
    QVERIFY(html.contains(QStringLiteral("class=\"copy\"")));
    QVERIFY(html.contains(QStringLiteral("navigator.clipboard")));
}

void TestGuide::guideMatchesApplicationPalette()
{
    QFile f(QStringLiteral(":/docs/guide.html"));
    QVERIFY(f.open(QIODevice::ReadOnly));
    const QString html = QString::fromUtf8(f.readAll());

    // The guide must use the same palette as qml/theme/Colors.qml so it reads
    // as part of the application rather than a separate document.
    QVERIFY2(html.contains(QStringLiteral("#ff9933")), "saffron accent missing");
    QVERIFY2(html.contains(QStringLiteral("#0d0f14")), "background colour missing");
    QVERIFY2(html.contains(QStringLiteral("GARVIT PANT")), "author credit missing");
}

QTEST_MAIN(TestGuide)
#include "test_guide.moc"
