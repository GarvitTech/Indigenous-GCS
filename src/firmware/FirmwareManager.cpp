#include "FirmwareManager.h"
#include "mavlink/MAVLinkManager.h"
#include "mavlink/MAVLinkSender.h"

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QSerialPortInfo>
#include <QStandardPaths>
#include <QLoggingCategory>
#include <QRegularExpression>

Q_LOGGING_CATEGORY(lcFirmware, "igcs.firmware")

namespace IndigenousGCS {

FirmwareManager::FirmwareManager(MAVLinkManager *mavlink, QObject *parent)
    : QObject(parent), m_mavlink(mavlink)
{
    refreshSerialPorts();
}

FirmwareManager::~FirmwareManager()
{
    cancelOperation();
    delete m_buildDir;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

QString FirmwareManager::findArduinoCli() const
{
    for (const QString &p : {"/opt/homebrew/bin/arduino-cli",
                              "/usr/local/bin/arduino-cli",
                              "/usr/bin/arduino-cli"}) {
        if (QFile::exists(p)) return p;
    }
    return "arduino-cli";
}

QString FirmwareManager::findEsptool() const
{
    // Try python3 -m esptool first (most reliable after pip install)
    return QString();   // signal to use python3 -m esptool
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

QStringList FirmwareManager::supportedBoards() const
{
    return {
        "ESP32 DevKit V1",
        "ESP32 DOIT DevKit V1",
        "ESP32 WROVER",
        "ESP32-S2",
        "ESP32-S3",
        "ESP32-C3"
    };
}

QString FirmwareManager::boardFqbn(const QString &displayName) const
{
    static const QHash<QString, QString> boards = {
        {"ESP32 DevKit V1", "esp32:esp32:esp32"},
        {"ESP32 DOIT DevKit V1", "esp32:esp32:esp32doit-devkit-v1"},
        {"ESP32 WROVER", "esp32:esp32:esp32wrover"},
        {"ESP32-S2", "esp32:esp32:esp32s2"},
        {"ESP32-S3", "esp32:esp32:esp32s3"},
        {"ESP32-C3", "esp32:esp32:esp32c3"}
    };
    return boards.value(displayName);
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
        emit operationFailed("Failed to create temporary build directory.");
        return;
    }

    const QString sketchDir  = m_buildDir->path() + "/FlightController";
    const QString sketchFile = sketchDir + "/FlightController.ino";
    QDir().mkpath(sketchDir);

    QFile f(sketchFile);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit operationFailed("Failed to write sketch file.");
        return;
    }
    QTextStream(&f) << sketchCode;
    f.close();

    const QString buildOutput = m_buildDir->path() + "/build";
    QDir().mkpath(buildOutput);

    // arduino-cli compile --fqbn <board> --output-dir <dir> <sketch>
    const QString cli = findArduinoCli();
    QStringList args = {
        "compile",
        "--fqbn", m_selectedBoard,
        "--output-dir", buildOutput,
        "--warnings", "default",
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
        appendCompileLog("\n[ERROR] arduino-cli not found or failed to start.\n"
                         "Install with: brew install arduino-cli\n"
                         "Then add ESP32 core: arduino-cli core install esp32:esp32\n");
        m_compiling = false;
        emit compilingChanged();
        emit operationFailed("arduino-cli not found.");
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
        flashBinary(m_binaryPath, m_pendingFlashPort);
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

    // Use python3 -m esptool
    const QString python = "/opt/homebrew/bin/python3";
    QStringList args = {
        "-m", "esptool",
        "--chip",  "esp32",
        "--port",  port,
        "--baud",  QString::number(m_flashBaud),
        "--before", "default_reset",
        "--after",  "hard_reset",
        "write_flash",
        "-z",
        "--flash_mode", "dio",
        "--flash_freq", "40m",
        "--flash_size", "detect",
        "0x10000",   // standard ESP32 app offset
        binPath
    };

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
        appendFlashLog("\n[ERROR] esptool failed to start. Install with:\n  pip3 install esptool --break-system-packages\n");
        m_flashing = false;
        emit flashingChanged();
        emit operationFailed("esptool not found.");
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
    m_flashAfterCompile = true;
    m_pendingFlashPort  = port;
    compileSketch(sketchCode);
}

} // namespace IndigenousGCS
