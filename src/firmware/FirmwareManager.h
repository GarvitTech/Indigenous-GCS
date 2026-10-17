#pragma once
#include <QObject>
#include <QString>
#include <QProcess>
#include <QTemporaryDir>
#include <QStringList>
#include <QHash>
#include <QVariantList>

namespace IndigenousGCS {

class MAVLinkManager;

class FirmwareManager : public QObject
{
    Q_OBJECT

    // Firmware info
    Q_PROPERTY(QString currentVersion  READ currentVersion  NOTIFY firmwareInfoChanged)
    Q_PROPERTY(QString boardType       READ boardType       NOTIFY firmwareInfoChanged)
    Q_PROPERTY(QString buildDate       READ buildDate       NOTIFY firmwareInfoChanged)

    // Compile state
    Q_PROPERTY(bool    compiling       READ compiling       NOTIFY compilingChanged)
    Q_PROPERTY(int     compileProgress READ compileProgress NOTIFY compileProgressChanged)
    Q_PROPERTY(QString compileLog      READ compileLog      NOTIFY compileLogChanged)
    Q_PROPERTY(QString binaryPath     READ binaryPath      NOTIFY binaryPathChanged)

    // Flash state
    Q_PROPERTY(bool    flashing        READ flashing        NOTIFY flashingChanged)
    Q_PROPERTY(int     flashProgress   READ flashProgress   NOTIFY flashProgressChanged)
    Q_PROPERTY(QString flashLog        READ flashLog        NOTIFY flashLogChanged)

    // Available serial ports for flashing
    Q_PROPERTY(QStringList serialPorts READ serialPorts     NOTIFY serialPortsChanged)
    Q_PROPERTY(QStringList availableBoards READ availableBoards NOTIFY availableBoardsChanged)
    Q_PROPERTY(QVariantList boardPickerItems READ boardPickerItems NOTIFY availableBoardsChanged)
    Q_PROPERTY(QString arduinoCliPath READ arduinoCliPath WRITE setArduinoCliPath NOTIFY arduinoCliPathChanged)
    Q_PROPERTY(bool arduinoCliAvailable READ arduinoCliAvailable NOTIFY arduinoCliPathChanged)
    Q_PROPERTY(QString boardListStatus READ boardListStatus NOTIFY boardListStatusChanged)

    // Board selection
    Q_PROPERTY(QString selectedBoard   READ selectedBoard   WRITE setSelectedBoard   NOTIFY selectedBoardChanged)
    Q_PROPERTY(QString selectedPort    READ selectedPort    WRITE setSelectedPort    NOTIFY selectedPortChanged)
    Q_PROPERTY(int     flashBaud       READ flashBaud       WRITE setFlashBaud       NOTIFY flashBaudChanged)

public:
    explicit FirmwareManager(MAVLinkManager *mavlink, QObject *parent = nullptr);
    ~FirmwareManager();

    QString currentVersion() const { return m_version; }
    QString boardType()      const { return m_boardType; }
    QString buildDate()      const { return m_buildDate; }

    bool    compiling()       const { return m_compiling; }
    int     compileProgress() const { return m_compileProgress; }
    QString compileLog()      const { return m_compileLog; }
    QString binaryPath()      const { return m_binaryPath; }

    bool    flashing()        const { return m_flashing; }
    int     flashProgress()   const { return m_flashProgress; }
    QString flashLog()        const { return m_flashLog; }

    QStringList serialPorts() const { return m_serialPorts; }
    QStringList availableBoards() const { return m_availableBoards; }
    QVariantList boardPickerItems() const { return m_boardPickerItems; }
    QString arduinoCliPath() const { return m_arduinoCliPath; }
    bool arduinoCliAvailable() const;
    QString boardListStatus() const { return m_boardListStatus; }

    QString selectedBoard()   const { return m_selectedBoard; }
    QString selectedPort()    const { return m_selectedPort; }
    int     flashBaud()       const { return m_flashBaud; }

    void setSelectedBoard(const QString &b) { if (m_selectedBoard != b) { m_selectedBoard = b; emit selectedBoardChanged(); } }
    void setSelectedPort(const QString &p)  { if (m_selectedPort  != p) { m_selectedPort  = p; emit selectedPortChanged();  } }
    void setFlashBaud(int baud)             { if (m_flashBaud     != baud) { m_flashBaud  = baud; emit flashBaudChanged();  } }
    void setArduinoCliPath(const QString &path);

    Q_INVOKABLE void requestFirmwareInfo(uint8_t targetSys, uint8_t targetComp);
    Q_INVOKABLE void refreshSerialPorts();
    Q_INVOKABLE void refreshBoards();
    Q_INVOKABLE QString boardFqbn(const QString &displayName) const;

    // Compile Arduino sketch source code → binary
    Q_INVOKABLE void compileSketch(const QString &sketchCode);

    // Flash a binary file to ESP32 via esptool
    Q_INVOKABLE void flashBinary(const QString &binPath, const QString &port);

    // One-shot: compile then flash
    Q_INVOKABLE void compileAndFlash(const QString &sketchCode, const QString &port);

    Q_INVOKABLE void cancelOperation();

signals:
    void firmwareInfoChanged();
    void compilingChanged();
    void compileProgressChanged();
    void compileLogChanged();
    void binaryPathChanged();
    void flashingChanged();
    void flashProgressChanged();
    void flashLogChanged();
    void serialPortsChanged();
    void availableBoardsChanged();
    void arduinoCliPathChanged();
    void boardListStatusChanged();
    void selectedBoardChanged();
    void selectedPortChanged();
    void flashBaudChanged();
    void operationSucceeded(const QString &message);
    void operationFailed(const QString &message);

private slots:
    void onCompileReadyRead();
    void onCompileFinished(int exitCode, QProcess::ExitStatus status);
    void onFlashReadyRead();
    void onFlashFinished(int exitCode, QProcess::ExitStatus status);
    void onBoardListFinished(int exitCode, QProcess::ExitStatus status);

private:
    void appendCompileLog(const QString &text);
    void appendFlashLog(const QString &text);
    QString findArduinoCli() const;
    // Built-in board list used when Arduino CLI is unavailable. Keeps the board
    // picker usable (ESP32 + common dev boards) without requiring the CLI.
    void applyFallbackBoards(const QString &reason);
    void uploadCompiledSketch(const QString &port);
    void setBoardListStatus(const QString &message);

    MAVLinkManager     *m_mavlink;
    QString             m_version;
    QString             m_boardType;
    QString             m_buildDate;

    bool                m_compiling       = false;
    int                 m_compileProgress = 0;
    QString             m_compileLog;
    QString             m_binaryPath;

    bool                m_flashing        = false;
    int                 m_flashProgress   = 0;
    QString             m_flashLog;

    QStringList         m_serialPorts;
    QStringList         m_availableBoards;
    QVariantList        m_boardPickerItems;
    QHash<QString, QString> m_boardFqbnByName;
    QString             m_arduinoCliPath;
    QString             m_boardListStatus;
    QString             m_selectedBoard;
    QString             m_selectedPort;
    int                 m_flashBaud       = 921600;

    QProcess           *m_compileProcess  = nullptr;
    QProcess           *m_flashProcess    = nullptr;
    QProcess           *m_boardProcess    = nullptr;
    QTemporaryDir      *m_buildDir        = nullptr;

    bool                m_flashAfterCompile = false;
    QString             m_pendingFlashPort;
};

} // namespace IndigenousGCS
