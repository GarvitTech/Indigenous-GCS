#pragma once

#include <QByteArray>
#include <QObject>
#include <QTimer>
#include <QVariantList>

#include "MSPParser.h"

namespace IndigenousGCS {

class ConnectionManager;

class MSPManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool waiting READ waiting NOTIFY waitingChanged)
    Q_PROPERTY(quint8 lastCommand READ lastCommand NOTIFY responseReceived)
    Q_PROPERTY(QString protocol READ protocol CONSTANT)
    Q_PROPERTY(QString apiVersion READ apiVersion NOTIFY identityChanged)
    Q_PROPERTY(QString fcVariant READ fcVariant NOTIFY identityChanged)
    Q_PROPERTY(QString fcVersion READ fcVersion NOTIFY identityChanged)
    Q_PROPERTY(QString boardIdentifier READ boardIdentifier NOTIFY identityChanged)
    Q_PROPERTY(int armingFlags READ armingFlags NOTIFY telemetryChanged)
    Q_PROPERTY(int roll READ roll NOTIFY telemetryChanged)
    Q_PROPERTY(int pitch READ pitch NOTIFY telemetryChanged)
    Q_PROPERTY(int yaw READ yaw NOTIFY telemetryChanged)
    Q_PROPERTY(int altitude READ altitude NOTIFY telemetryChanged)
    Q_PROPERTY(int batteryVoltage READ batteryVoltage NOTIFY telemetryChanged)
    Q_PROPERTY(int batteryCurrent READ batteryCurrent NOTIFY telemetryChanged)
    Q_PROPERTY(int batteryRemaining READ batteryRemaining NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList rcChannels READ rcChannels NOTIFY receiverChanged)
    Q_PROPERTY(QVariantList motorOutputs READ motorOutputs NOTIFY outputsChanged)
    Q_PROPERTY(QVariantList servoOutputs READ servoOutputs NOTIFY outputsChanged)
    Q_PROPERTY(QVariantList modeNames READ modeNames NOTIFY modesChanged)
    Q_PROPERTY(QVariantList modeIds READ modeIds NOTIFY modesChanged)
    Q_PROPERTY(QVariantList pidValues READ pidValues NOTIFY pidChanged)
    Q_PROPERTY(bool pidLoaded READ pidLoaded NOTIFY pidChanged)

public:
    explicit MSPManager(ConnectionManager *connection, QObject *parent = nullptr);

    bool waiting() const { return m_waiting; }
    quint8 lastCommand() const { return m_lastCommand; }
    QString protocol() const { return QStringLiteral("MSP v1"); }
    QString apiVersion() const { return m_apiVersion; }
    QString fcVariant() const { return m_fcVariant; }
    QString fcVersion() const { return m_fcVersion; }
    QString boardIdentifier() const { return m_boardIdentifier; }
    int armingFlags() const { return m_armingFlags; }
    int roll() const { return m_roll; }
    int pitch() const { return m_pitch; }
    int yaw() const { return m_yaw; }
    int altitude() const { return m_altitude; }
    int batteryVoltage() const { return m_batteryVoltage; }
    int batteryCurrent() const { return m_batteryCurrent; }
    int batteryRemaining() const { return m_batteryRemaining; }
    QVariantList rcChannels() const { return m_rcChannels; }
    QVariantList motorOutputs() const { return m_motorOutputs; }
    QVariantList servoOutputs() const { return m_servoOutputs; }
    QVariantList modeNames() const { return m_modeNames; }
    QVariantList modeIds() const { return m_modeIds; }
    QVariantList pidValues() const { return m_pidValues; }
    bool pidLoaded() const { return m_pidPayload.size() >= 9; }

    Q_INVOKABLE void request(int command);
    Q_INVOKABLE void requestWithPayload(int command, const QByteArray &payload);
    Q_INVOKABLE void setPid(int rollP, int rollI, int rollD,
                            int pitchP, int pitchI, int pitchD,
                            int yawP, int yawI, int yawD);
    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void cancelRequest();

signals:
    void waitingChanged();
    void identityChanged();
    void telemetryChanged();
    void receiverChanged();
    void outputsChanged();
    void modesChanged();
    void pidChanged();
    void responseReceived(int command, const QByteArray &payload);
    void requestTimedOut(int command);
    void protocolError(const QString &message);

private slots:
    void onBytesReceived(const QByteArray &data);
    void onMessageReceived(const MSPMessage &message);
    void onTimeout();

private:
    void sendRequest(quint8 command, const QByteArray &payload);
    void updateState(const MSPMessage &message);

    ConnectionManager *m_connection;
    MSPParser m_parser;
    QTimer m_timeoutTimer;
    bool m_waiting = false;
    quint8 m_lastCommand = 0;
    QString m_apiVersion;
    QString m_fcVariant;
    QString m_fcVersion;
    QString m_boardIdentifier;
    int m_armingFlags = 0;
    int m_roll = 0;
    int m_pitch = 0;
    int m_yaw = 0;
    int m_altitude = 0;
    int m_batteryVoltage = 0;
    int m_batteryCurrent = 0;
    int m_batteryRemaining = -1;
    QVariantList m_rcChannels;
    QVariantList m_motorOutputs;
    QVariantList m_servoOutputs;
    QVariantList m_modeNames;
    QVariantList m_modeIds;
    QByteArray m_pidPayload;
    QVariantList m_pidValues;
};

} // namespace IndigenousGCS
