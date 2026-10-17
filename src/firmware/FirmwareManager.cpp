#include "FirmwareManager.h"
#include "mavlink/MAVLinkManager.h"
#include "mavlink/MAVLinkSender.h"

#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QTextStream>
#include <QSerialPortInfo>
#include <QStandardPaths>
#include <QSettings>
#include <QLoggingCategory>
#include <QRegularExpression>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QVariantMap>
#include <algorithm>

Q_LOGGING_CATEGORY(lcFirmware, "igcs.firmware")

namespace IndigenousGCS {

FirmwareManager::FirmwareManager(MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent), m_mavlink(mavlink)
{
    QSettings settings;
    m_arduinoCliPath = settings.value("firmware/arduinoCliPath").toString();
    if (m_arduinoCliPath.isEmpty())
        m_arduinoCliPath = qEnvironmentVariable("ARDUINO_CLI_PATH");
    if (m_arduinoCliPath.isEmpty())
        m_arduinoCliPath = findArduinoCli();
    refreshSerialPorts();
    refreshBoards();
}

FirmwareManager::~FirmwareManager()
{
    cancelOperation();
    delete m_buildDir;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

QString FirmwareManager::findArduinoCli() const
{
    if (!m_arduinoCliPath.isEmpty()) {
        const QFileInfo configured(m_arduinoCliPath);
        if (configured.isFile() && configured.isExecutable())
            return configured.absoluteFilePath();
        const QString executable = QStandardPaths::findExecutable(m_arduinoCliPath);
        return executable;
    }

    const QString executable = QStandardPaths::findExecutable("arduino-cli");
    if (!executable.isEmpty())
        return executable;

    QStringList candidates;
#ifdef Q_OS_MACOS
    candidates << "/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/arduino-cli"
               << QDir::homePath() + "/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/arduino-cli";
#elif defined(Q_OS_WIN)
    const QString programFiles = qEnvironmentVariable("ProgramFiles");
    const QString localAppData = qEnvironmentVariable("LOCALAPPDATA");
    const QString programFilesX86 = qEnvironmentVariable("ProgramFiles(x86)");
    if (!programFiles.isEmpty())
        candidates << programFiles + "/Arduino IDE/resources/app/lib/backend/arduino-cli.exe";
    if (!programFilesX86.isEmpty())
        candidates << programFilesX86 + "/Arduino IDE/resources/app/lib/backend/arduino-cli.exe";
    if (!localAppData.isEmpty())
        candidates << localAppData + "/Programs/Arduino IDE/resources/app/lib/backend/arduino-cli.exe";
#else
    candidates << "/opt/arduino-ide/resources/app/lib/backend/arduino-cli"
               << "/usr/lib/arduino-ide/resources/app/lib/backend/arduino-cli";
#endif
    for (const QString &candidate : candidates) {
        const QFileInfo file(candidate);
        if (file.isFile() && file.isExecutable())
            return file.absoluteFilePath();
    }
    return {};
}

bool FirmwareManager::arduinoCliAvailable() const
{
    return !findArduinoCli().isEmpty();
}

void FirmwareManager::setArduinoCliPath(const QString &path)
{
    const QString normalized = path.trimmed();
    if (m_arduinoCliPath == normalized)
        return;
    m_arduinoCliPath = normalized;
    QSettings settings;
    settings.setValue("firmware/arduinoCliPath", m_arduinoCliPath);
    emit arduinoCliPathChanged();
    refreshBoards();
}

void FirmwareManager::setBoardListStatus(const QString &message)
{
    if (m_boardListStatus == message)
        return;
    m_boardListStatus = message;
    emit boardListStatusChanged();
}

QString FirmwareManager::boardFqbn(const QString &displayName) const
{
    return m_boardFqbnByName.value(displayName);
}

void FirmwareManager::refreshBoards()
{
    if (m_boardProcess) {
        QProcess *previousProcess = m_boardProcess;
        m_boardProcess = nullptr;
        disconnect(previousProcess, nullptr, this, nullptr);
        if (previousProcess->state() != QProcess::NotRunning) {
            previousProcess->kill();
            previousProcess->waitForFinished(1000);
        }
        previousProcess->deleteLater();
    }

    const QString cli = findArduinoCli();
    if (cli.isEmpty()) {
        // Arduino CLI is not installed. Rather than leaving the board picker
        // empty (which makes the page look broken), fall back to a built-in
        // list of common ESP32 / dev boards. FQBNs match Arduino CLI naming so
        // flashing still works if the CLI is installed later.
        applyFallbackBoards("Arduino CLI not found. Showing built-in board list. "
                            "Set the CLI path below to flash directly.");
        return;
    }

    setBoardListStatus("Loading boards installed in Arduino CLI...");
    m_boardProcess = new QProcess(this);
    connect(m_boardProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &FirmwareManager::onBoardListFinished);
    m_boardProcess->start(cli, {"board", "listall", "--show-hidden", "--json"});
    if (!m_boardProcess->waitForStarted(3000)) {
        m_boardProcess->deleteLater();
        m_boardProcess = nullptr;
        setBoardListStatus("Could not start Arduino CLI. Check the executable path.");
    }
}

void FirmwareManager::onBoardListFinished(int exitCode, QProcess::ExitStatus status)
{
    QProcess *process = m_boardProcess;
    m_boardProcess = nullptr;
    if (!process)
        return;

    const QByteArray output = process->readAllStandardOutput();
    const QString errorOutput = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
    process->deleteLater();
    if (status != QProcess::NormalExit || exitCode != 0) {
        applyFallbackBoards(errorOutput.isEmpty()
            ? QString("Arduino CLI could not list boards. Showing built-in board list.")
            : errorOutput);
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(output, &parseError);
    const QJsonArray boardItems = document.object().value("boards").toArray();
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        const bool hadBoards = !m_availableBoards.isEmpty();
        m_boardFqbnByName.clear();
        m_availableBoards.clear();
        m_boardPickerItems.clear();
        if (hadBoards)
            emit availableBoardsChanged();
        setBoardListStatus("Arduino CLI returned an invalid board list.");
        qCWarning(lcFirmware) << "Invalid board list JSON:" << parseError.errorString();
        return;
    }

    struct BoardEntry {
        QString name;
        QString fqbn;
        QString category;
    };
    QVector<BoardEntry> boards;
    QHash<QString, int> nameCounts;
    for (const QJsonValue &value : boardItems) {
        const QJsonObject item = value.toObject();
        const QString name = item.value("name").toString().trimmed();
        const QString fqbn = item.value("fqbn").toString().trimmed();
        if (name.isEmpty() || fqbn.isEmpty())
            continue;
        const QJsonObject platform = item.value("platform").toObject();
        const QJsonObject metadata = platform.value("metadata").toObject();
        QString category = metadata.value("name").toString().trimmed();
        if (category.isEmpty()) {
            const QStringList fqbnParts = fqbn.split(':');
            category = fqbnParts.size() >= 2
                ? fqbnParts.at(0) + " · " + fqbnParts.at(1)
                : "Other platforms";
        }
        boards.append({name, fqbn, category});
        ++nameCounts[name];
    }

    std::sort(boards.begin(), boards.end(), [](const auto &left, const auto &right) {
        const int byCategory = QString::localeAwareCompare(left.category, right.category);
        if (byCategory != 0)
            return byCategory < 0;
        const int byName = QString::localeAwareCompare(left.name, right.name);
        return byName == 0 ? left.fqbn < right.fqbn : byName < 0;
    });

    const QString previousBoard = m_selectedBoard;
    QStringList names;
    QHash<QString, QString> fqbnByName;
    QVariantList pickerItems;
    for (const auto &board : boards) {
        const QString displayName = nameCounts.value(board.name) > 1
            ? board.name + " (" + board.fqbn + ")"
            : board.name;
        names.append(displayName);
        fqbnByName.insert(displayName, board.fqbn);
        QVariantMap pickerItem;
        pickerItem.insert("name", displayName);
        pickerItem.insert("fqbn", board.fqbn);
        pickerItem.insert("category", board.category);
        pickerItems.append(pickerItem);
    }
    m_availableBoards = names;
    m_boardPickerItems = pickerItems;
    m_boardFqbnByName = fqbnByName;
    emit availableBoardsChanged();

    if (fqbnByName.values().contains(previousBoard)) {
        setBoardListStatus(QString("%1 boards available").arg(names.size()));
    } else {
        const QString esp32Board = "esp32:esp32:esp32";
        const QString selected = fqbnByName.values().contains(esp32Board)
            ? esp32Board
            : (boards.isEmpty() ? QString() : boards.first().fqbn);
        if (m_selectedBoard != selected) {
            m_selectedBoard = selected;
            emit selectedBoardChanged();
        }
        setBoardListStatus(names.isEmpty()
            ? "No boards found. Install a platform in Boards Manager, then refresh."
            : QString("%1 boards available").arg(names.size()));
    }
}

void FirmwareManager::applyFallbackBoards(const QString &reason)
{
    // Built-in list of boards relevant to this project. FQBNs use Arduino
    // naming so they are valid once the matching core is installed via the CLI.
    struct FallbackBoard { const char *name; const char *fqbn; const char *category; };
    static const FallbackBoard kBuiltInBoards[] = {
        { "ESP32 Dev Module",           "esp32:esp32:esp32",              "ESP32 · Espressif" },
        { "ESP32-S3 Dev Module",        "esp32:esp32:esp32s3",            "ESP32 · Espressif" },
        { "ESP32-C3 Dev Module",        "esp32:esp32:esp32c3",            "ESP32 · Espressif" },
        { "ESP32-S2 Dev Module",        "esp32:esp32:esp32s2",            "ESP32 · Espressif" },
        { "ESP32 Wrover Module",        "esp32:esp32:esp32wrover",        "ESP32 · Espressif" },
        { "NodeMCU-32S",                "esp32:esp32:nodemcu-32s",        "ESP32 · Espressif" },
        { "Arduino Uno",                "arduino:avr:uno",                "Arduino · AVR" },
        { "Arduino Nano",               "arduino:avr:nano",               "Arduino · AVR" },
        { "Arduino Mega or Mega 2560",   "arduino:avr:mega",               "Arduino · AVR" },
        { "Raspberry Pi Pico",          "rp2040:rp2040:rpipico",          "RP2040 · Raspberry Pi" },
    };

    QStringList names;
    QVariantList pickerItems;
    QHash<QString, QString> fqbnByName;
    for (const FallbackBoard &board : kBuiltInBoards) {
        const QString displayName = QString::fromUtf8(board.name);
        names.append(displayName);
        fqbnByName.insert(displayName, QString::fromUtf8(board.fqbn));
        QVariantMap pickerItem;
        pickerItem.insert("name", displayName);
        pickerItem.insert("fqbn", QString::fromUtf8(board.fqbn));
        pickerItem.insert("category", QString::fromUtf8(board.category));
        pickerItems.append(pickerItem);
    }
    m_availableBoards = names;
    m_boardPickerItems = pickerItems;
    m_boardFqbnByName = fqbnByName;
    emit availableBoardsChanged();

    if (!m_selectedBoard.isEmpty() && !fqbnByName.values().contains(m_selectedBoard)) {
        m_selectedBoard = "esp32:esp32:esp32";
        emit selectedBoardChanged();
    } else if (m_selectedBoard.isEmpty()) {
        m_selectedBoard = "esp32:esp32:esp32";
        emit selectedBoardChanged();
    }
    setBoardListStatus(reason);
}

void FirmwareManager::appendCompileLog(const QString &text)
{
    m_compileLog += text;
    emit compileLogChanged();
}

void FirmwareManager::appendFlashLog(const QString &text)
{
    m_flashLog += text;
    emit flashLogChanged();
}

// ── Serial ports ─────────────────────────────────────────────────────────────

void FirmwareManager::refreshSerialPorts()
{
    m_serialPorts.clear();
    for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts()) {
        m_serialPorts << info.portName();
    }
    if (!m_serialPorts.isEmpty() && m_selectedPort.isEmpty())
        m_selectedPort = m_serialPorts.first();
    emit serialPortsChanged();
}

// ── MAVLink firmware info ─────────────────────────────────────────────────────

void FirmwareManager::requestFirmwareInfo(uint8_t targetSys, uint8_t targetComp)
{
    m_mavlink->sender()->sendCommandLong(targetSys, targetComp,
                                         MAV_CMD_REQUEST_AUTOPILOT_CAPABILITIES, 1.0f);
}

// ── Cancel ────────────────────────────────────────────────────────────────────

void FirmwareManager::cancelOperation()
{
    m_flashAfterCompile = false;
    if (m_boardProcess && m_boardProcess->state() != QProcess::NotRunning) {
        m_boardProcess->kill();
        m_boardProcess->waitForFinished(2000);
    }
    if (m_compileProcess && m_compileProcess->state() != QProcess::NotRunning) {
        m_compileProcess->kill();
        m_compileProcess->waitForFinished(2000);
    }
    if (m_flashProcess && m_flashProcess->state() != QProcess::NotRunning) {
        m_flashProcess->kill();
        m_flashProcess->waitForFinished(2000);
    }
    if (m_compiling) { m_compiling = false; emit compilingChanged(); }
    if (m_flashing)  { m_flashing  = false; emit flashingChanged();  }
}

// ── Compile ───────────────────────────────────────────────────────────────────

void FirmwareManager::compileSketch(const QString &sketchCode)
{
    if (m_compiling || m_flashing) return;

    const QString cli = findArduinoCli();
    if (cli.isEmpty()) {
        m_flashAfterCompile = false;
        const QString message = "Arduino CLI was not found. Set the executable path on this page, install Arduino IDE/CLI, or add arduino-cli to PATH.";
        m_compileLog = "[ERROR] " + message + "\n";
        emit compileLogChanged();
        setBoardListStatus(message);
        emit operationFailed(message);
        return;
    }
    if (m_selectedBoard.isEmpty()) {
        m_flashAfterCompile = false;
        emit operationFailed("No board selected. Install its platform in Arduino IDE Boards Manager and refresh the board list.");
        return;
    }

    // Reset state
    m_compileLog.clear();
    m_binaryPath.clear();
    m_compileProgress = 0;
    emit compileLogChanged();
    emit binaryPathChanged();
    emit compileProgressChanged();

    // Create temp sketch directory — arduino-cli requires dir name == sketch name
    delete m_buildDir;
    m_buildDir = new QTemporaryDir();
    if (!m_buildDir->isValid()) {
        m_flashAfterCompile = false;
        emit operationFailed("Failed to create temporary build directory.");
        return;
    }

    const QString sketchDir  = m_buildDir->path() + "/FlightController";
    const QString sketchFile = sketchDir + "/FlightController.ino";
    QDir().mkpath(sketchDir);

    const QString librariesDir = sketchDir + "/libraries";
    const QString mavlinkLibraryDir = librariesDir + "/MAVLink";
    const QString mavlinkSourceDir = mavlinkLibraryDir + "/src";
    if (!QDir().mkpath(mavlinkSourceDir)) {
        m_flashAfterCompile = false;
        emit operationFailed("Failed to prepare the bundled MAVLink library.");
        return;
    }

    const QString resourceRoot = ":/firmware-mavlink";
    QDir resourceDirectory(resourceRoot);
    QDirIterator headers(resourceRoot, QDir::Files, QDirIterator::Subdirectories);
    while (headers.hasNext()) {
        const QString resourcePath = headers.next();
        const QString relativePath = resourceDirectory.relativeFilePath(resourcePath);
        const QString destinationPath = mavlinkSourceDir + "/" + relativePath;
        if (!QDir().mkpath(QFileInfo(destinationPath).path()) ||
            !QFile::copy(resourcePath, destinationPath)) {
            m_flashAfterCompile = false;
            emit operationFailed("Failed to copy bundled MAVLink headers for firmware compilation.");
            return;
        }
    }

    QFile libraryManifest(mavlinkLibraryDir + "/library.properties");
    if (!libraryManifest.open(QIODevice::WriteOnly | QIODevice::Text)) {
        m_flashAfterCompile = false;
        emit operationFailed("Failed to prepare the bundled MAVLink Arduino library.");
        return;
    }
    QTextStream(&libraryManifest)
        << "name=MAVLink\n"
           "version=2.0.0\n"
           "author=Indigenous GCS\n"
           "maintainer=Indigenous GCS\n"
           "sentence=MAVLink common dialect headers bundled with Indigenous GCS.\n"
           "paragraph=Generated MAVLink C headers for ESP32 firmware sketches.\n"
           "category=Communication\n"
           "architectures=*\n";

    QFile f(sketchFile);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        m_flashAfterCompile = false;
        emit operationFailed("Failed to write sketch file.");
        return;
    }
    QTextStream(&f) << sketchCode;
    f.close();

    const QString buildOutput = m_buildDir->path() + "/build";
    QDir().mkpath(buildOutput);

    // arduino-cli compile --fqbn <board> --output-dir <dir> <sketch>
    QStringList args = {
        "compile",
        "--fqbn", m_selectedBoard,
        "--output-dir", buildOutput,
        "--warnings", "default",
        "--libraries", librariesDir,
        sketchDir
    };

    appendCompileLog("=== Arduino Compile ===\n");
    appendCompileLog("Board : " + m_selectedBoard + "\n");
    appendCompileLog("Sketch: " + sketchFile + "\n");
    appendCompileLog("Output: " + buildOutput + "\n\n");

    m_compileProcess = new QProcess(this);
    connect(m_compileProcess, &QProcess::readyReadStandardOutput, this, &FirmwareManager::onCompileReadyRead);
    connect(m_compileProcess, &QProcess::readyReadStandardError,  this, &FirmwareManager::onCompileReadyRead);
    connect(m_compileProcess, QOverload<int,QProcess::ExitStatus>::of(&QProcess::finished),
            this, &FirmwareManager::onCompileFinished);

    m_compiling = true;
    emit compilingChanged();
    m_compileProcess->start(cli, args);

    if (!m_compileProcess->waitForStarted(5000)) {
        appendCompileLog("\n[ERROR] arduino-cli was not found or failed to start.\n"
                         "Set the Arduino CLI executable path on this page, install Arduino CLI, or add it to PATH.\n"
                         "Install a board platform in Boards Manager before compiling.\n");
        m_compiling = false;
        m_flashAfterCompile = false;
        emit compilingChanged();
        emit operationFailed("Arduino CLI could not be started. Set its executable path or add it to PATH.");
    }
}

void FirmwareManager::onCompileReadyRead()
{
    if (!m_compileProcess) return;
    const QString out = QString::fromUtf8(m_compileProcess->readAllStandardOutput());
    const QString err = QString::fromUtf8(m_compileProcess->readAllStandardError());
    if (!out.isEmpty()) appendCompileLog(out);
    if (!err.isEmpty()) appendCompileLog(err);

    // Estimate progress from output lines
    m_compileProgress = qMin(m_compileProgress + 3, 90);
    emit compileProgressChanged();
}

void FirmwareManager::onCompileFinished(int exitCode, QProcess::ExitStatus)
{
    m_compiling = false;
    m_compileProgress = exitCode == 0 ? 100 : 0;
    emit compilingChanged();
    emit compileProgressChanged();

    if (exitCode != 0) {
        appendCompileLog("\n[FAILED] Compilation failed with exit code " + QString::number(exitCode) + "\n");
        emit operationFailed("Compilation failed. Check the log for errors.");
        m_flashAfterCompile = false;
        return;
    }

    // Find the .bin file in build output
    const QString buildOutput = m_buildDir->path() + "/build";
    QDir dir(buildOutput);
    const QStringList bins = dir.entryList({"*.bin"}, QDir::Files);
    QString binFile;
    // Prefer the main firmware binary (not bootloader/partitions)
    for (const QString &b : bins) {
        if (!b.contains("bootloader") && !b.contains("partitions")) {
            binFile = dir.absoluteFilePath(b);
            break;
        }
    }
    if (binFile.isEmpty() && !bins.isEmpty())
        binFile = dir.absoluteFilePath(bins.first());

    if (binFile.isEmpty()) {
        appendCompileLog("\n[ERROR] No .bin file found in build output.\n");
        emit operationFailed("Compilation succeeded but no binary found.");
        m_flashAfterCompile = false;
        return;
    }

    m_binaryPath = binFile;
    emit binaryPathChanged();
    appendCompileLog("\n[OK] Binary: " + binFile + "\n");
    emit operationSucceeded("Compilation successful! Binary ready.");

    if (m_flashAfterCompile) {
        m_flashAfterCompile = false;
        uploadCompiledSketch(m_pendingFlashPort);
    }
}

void FirmwareManager::uploadCompiledSketch(const QString &port)
{
    const QString cli = findArduinoCli();
    if (cli.isEmpty()) {
        emit operationFailed("Arduino CLI was not found. Set its executable path on this page.");
        return;
    }
    if (port.isEmpty()) {
        emit operationFailed("No serial port selected.");
        return;
    }

    const QString sketchDir = m_buildDir->path() + "/FlightController";
    const QString buildOutput = m_buildDir->path() + "/build";
    const QStringList args = {
        "upload",
        "--fqbn", m_selectedBoard,
        "--port", port,
        "--input-dir", buildOutput,
        sketchDir
    };

    m_flashLog.clear();
    m_flashProgress = 0;
    emit flashLogChanged();
    emit flashProgressChanged();
    appendFlashLog("=== Upload compiled ESP32 firmware ===\n");
    appendFlashLog("Board : " + m_selectedBoard + "\n");
    appendFlashLog("Port  : " + port + "\n");
    appendFlashLog("Output: " + buildOutput + "\n\n");

    m_flashProcess = new QProcess(this);
    connect(m_flashProcess, &QProcess::readyReadStandardOutput, this, &FirmwareManager::onFlashReadyRead);
    connect(m_flashProcess, &QProcess::readyReadStandardError, this, &FirmwareManager::onFlashReadyRead);
    connect(m_flashProcess, QOverload<int,QProcess::ExitStatus>::of(&QProcess::finished),
            this, &FirmwareManager::onFlashFinished);

    m_flashing = true;
    emit flashingChanged();
    m_flashProcess->start(cli, args);
    if (!m_flashProcess->waitForStarted(5000)) {
        appendFlashLog("\n[ERROR] Arduino CLI upload could not start. Ensure arduino-cli is installed and on PATH.\n");
        m_flashing = false;
        emit flashingChanged();
        emit operationFailed("Arduino CLI could not start the firmware upload.");
    }
}

// ── Flash ─────────────────────────────────────────────────────────────────────

void FirmwareManager::flashBinary(const QString &binPath, const QString &port)
{
    if (m_flashing || m_compiling) return;
    if (binPath.isEmpty()) { emit operationFailed("No binary selected."); return; }
    if (port.isEmpty())    { emit operationFailed("No serial port selected."); return; }

    m_flashLog.clear();
    m_flashProgress = 0;
    emit flashLogChanged();
    emit flashProgressChanged();

    QString python = QStandardPaths::findExecutable("python3");
    QStringList args;
#ifdef Q_OS_WIN
    if (python.isEmpty()) {
        python = QStandardPaths::findExecutable("py");
        if (!python.isEmpty())
            args << "-3";
    }
#endif
    if (python.isEmpty())
        python = QStandardPaths::findExecutable("python");
    if (python.isEmpty()) {
        appendFlashLog("[ERROR] Python 3 was not found. Install Python 3 and esptool (`python -m pip install esptool`).\n");
        emit operationFailed("Python 3 is required to flash firmware. Install Python 3 and esptool.");
        return;
    }

    QString chip = "esp32";
    if (m_selectedBoard.contains(":esp32s2"))
        chip = "esp32s2";
    else if (m_selectedBoard.contains(":esp32s3"))
        chip = "esp32s3";
    else if (m_selectedBoard.contains(":esp32c3"))
        chip = "esp32c3";

    args << "-m" << "esptool" << "--chip" << chip
         << "--port" << port
         << "--baud" << QString::number(m_flashBaud)
         << "--before" << "default_reset"
         << "--after" << "hard_reset"
         << "write_flash"
         << "-z"
         << "--flash_mode" << "dio"
         << "--flash_freq" << "40m"
         << "--flash_size" << "detect"
         << "0x10000"
         << binPath;

    appendFlashLog("=== ESP32 Flash ===\n");
    appendFlashLog("Port  : " + port + "\n");
    appendFlashLog("Baud  : " + QString::number(m_flashBaud) + "\n");
    appendFlashLog("Binary: " + binPath + "\n\n");

    m_flashProcess = new QProcess(this);
    connect(m_flashProcess, &QProcess::readyReadStandardOutput, this, &FirmwareManager::onFlashReadyRead);
    connect(m_flashProcess, &QProcess::readyReadStandardError,  this, &FirmwareManager::onFlashReadyRead);
    connect(m_flashProcess, QOverload<int,QProcess::ExitStatus>::of(&QProcess::finished),
            this, &FirmwareManager::onFlashFinished);

    m_flashing = true;
    emit flashingChanged();
    m_flashProcess->start(python, args);

    if (!m_flashProcess->waitForStarted(5000)) {
        appendFlashLog("\n[ERROR] esptool failed to start. Install with:\n  python -m pip install esptool\n");
        m_flashing = false;
        emit flashingChanged();
        emit operationFailed("esptool could not be started. Install it with Python 3 and ensure it is available to the selected interpreter.");
    }
}

void FirmwareManager::onFlashReadyRead()
{
    if (!m_flashProcess) return;
    const QString out = QString::fromUtf8(m_flashProcess->readAllStandardOutput());
    const QString err = QString::fromUtf8(m_flashProcess->readAllStandardError());
    const QString combined = out + err;
    if (!combined.isEmpty()) appendFlashLog(combined);

    // Parse esptool progress: "Writing at 0x00010000... (5 %)"
    static QRegularExpression re(R"(\((\d+)\s*%\))");
    QRegularExpressionMatchIterator it = re.globalMatch(combined);
    while (it.hasNext()) {
        m_flashProgress = it.next().captured(1).toInt();
        emit flashProgressChanged();
    }
}

void FirmwareManager::onFlashFinished(int exitCode, QProcess::ExitStatus)
{
    m_flashing = false;
    m_flashProgress = exitCode == 0 ? 100 : 0;
    emit flashingChanged();
    emit flashProgressChanged();

    if (exitCode != 0) {
        appendFlashLog("\n[FAILED] Flash failed with exit code " + QString::number(exitCode) + "\n");
        emit operationFailed("Flash failed. Check port, baud rate, and ESP32 boot mode.");
    } else {
        appendFlashLog("\n[OK] Flash complete! ESP32 is rebooting...\n");
        emit operationSucceeded("Firmware flashed successfully! ESP32 is running.");
    }
}

// ── Compile + Flash ───────────────────────────────────────────────────────────

void FirmwareManager::compileAndFlash(const QString &sketchCode, const QString &port)
{
    if (m_compiling || m_flashing) return;
    if (port.isEmpty()) {
        emit operationFailed("No serial port selected.");
        return;
    }
    m_flashAfterCompile = true;
    m_pendingFlashPort  = port;
    compileSketch(sketchCode);
}

} // namespace IndigenousGCS
