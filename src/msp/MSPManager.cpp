#include "MSPManager.h"

#include "communication/ConnectionManager.h"

namespace IndigenousGCS {

namespace {

constexpr quint8 kMspApiVersion = 1;
constexpr quint8 kMspFcVariant = 2;
constexpr quint8 kMspFcVersion = 3;
constexpr quint8 kMspBoardInfo = 4;
constexpr quint8 kMspStatus = 101;
constexpr quint8 kMspAttitude = 108;
constexpr quint8 kMspAltitude = 109;
constexpr quint8 kMspAnalog = 110;
constexpr quint8 kMspRc = 105;
constexpr quint8 kMspServo = 103;
constexpr quint8 kMspMotor = 104;
constexpr quint8 kMspBoxNames = 116;
constexpr quint8 kMspBoxIds = 119;
constexpr quint8 kMspPid = 112;
constexpr quint8 kMspSetPid = 202;
constexpr quint8 kMspEepromWrite = 250;

quint16 readU16(const QByteArray &payload, int offset)
{
    if (offset < 0 || offset + 2 > payload.size()) return 0;
    return static_cast<quint16>(static_cast<quint8>(payload.at(offset)))
         | static_cast<quint16>(static_cast<quint8>(payload.at(offset + 1))) << 8;
}

qint16 readS16(const QByteArray &payload, int offset)
{
    return static_cast<qint16>(readU16(payload, offset));
}

qint32 readS32(const QByteArray &payload, int offset)
{
    if (offset < 0 || offset + 4 > payload.size()) return 0;
    return static_cast<qint32>(static_cast<quint8>(payload.at(offset)))
         | static_cast<qint32>(static_cast<quint8>(payload.at(offset + 1))) << 8
         | static_cast<qint32>(static_cast<quint8>(payload.at(offset + 2))) << 16
         | static_cast<qint32>(static_cast<quint8>(payload.at(offset + 3))) << 24;
}

QString readString(const QByteArray &payload)
{
    const auto nul = payload.indexOf('\0');
    return QString::fromLatin1(nul >= 0 ? payload.left(nul) : payload);
}

QVariantList readNullSeparatedStrings(const QByteArray &payload)
{
    QVariantList result;
    for (const auto &part : payload.split('\0')) {
        if (!part.isEmpty()) result.append(QString::fromLatin1(part));
    }
    return result;
}

}

MSPManager::MSPManager(ConnectionManager *connection, QObject *parent)
    : QObject(parent), m_connection(connection), m_parser(this)
{
    m_timeoutTimer.setSingleShot(true);
    m_timeoutTimer.setInterval(1000);
    connect(m_connection, &ConnectionManager::bytesReceived,
            this, &MSPManager::onBytesReceived);
    connect(&m_parser, &MSPParser::messageReceived,
            this, &MSPManager::onMessageReceived);
    connect(&m_timeoutTimer, &QTimer::timeout,
            this, &MSPManager::onTimeout);
}

void MSPManager::request(int command)
{
    requestWithPayload(command, {});
}

void MSPManager::requestWithPayload(int command, const QByteArray &payload)
{
    if (command < 0 || command > 255) {
        emit protocolError(QStringLiteral("MSP command must be between 0 and 255."));
        return;
    }
    sendRequest(static_cast<quint8>(command), payload);
}

void MSPManager::setPid(int rollP, int rollI, int rollD,
                        int pitchP, int pitchI, int pitchD,
                        int yawP, int yawI, int yawD)
{
    const QList<int> values = {rollP, rollI, rollD, pitchP, pitchI, pitchD, yawP, yawI, yawD};
    for (const auto value : values) {
        if (value < 0 || value > 255) {
            emit protocolError(QStringLiteral("PID values must be between 0 and 255."));
            return;
        }
    }
    if (!pidLoaded()) {
        emit protocolError(QStringLiteral("Read the flight-controller PID profile before writing it."));
        return;
    }

    QByteArray payload = m_pidPayload;
    for (qsizetype index = 0; index < values.size(); ++index)
        payload[index] = static_cast<char>(values.at(index));
    sendRequest(kMspSetPid, payload);
}

void MSPManager::saveSettings()
{
    sendRequest(kMspEepromWrite, {});
}

void MSPManager::sendRequest(quint8 command, const QByteArray &payload)
{
    if (!m_connection->isConnected()) {
        emit protocolError(QStringLiteral("Connect to an INAV flight controller first."));
        return;
    }

    m_connection->sendBytes(MSPParser::encodeRequest(command, payload));
    m_lastCommand = command;
    if (!m_waiting) {
        m_waiting = true;
        emit waitingChanged();
    }
    m_timeoutTimer.start();
}

void MSPManager::cancelRequest()
{
    m_timeoutTimer.stop();
    if (m_waiting) {
        m_waiting = false;
        emit waitingChanged();
    }
}

void MSPManager::onBytesReceived(const QByteArray &data)
{
    m_parser.parseBytes(data);
}

void MSPManager::onMessageReceived(const MSPMessage &message)
{
    updateState(message);
    if (m_waiting && message.command == m_lastCommand)
        cancelRequest();
    emit responseReceived(message.command, message.payload);
}

void MSPManager::updateState(const MSPMessage &message)
{
    switch (message.command) {
    case kMspApiVersion:
        if (message.payload.size() >= 3)
            m_apiVersion = QStringLiteral("%1.%2.%3")
                .arg(static_cast<quint8>(message.payload.at(0)))
                .arg(static_cast<quint8>(message.payload.at(1)))
                .arg(static_cast<quint8>(message.payload.at(2)));
        emit identityChanged();
        break;
    case kMspFcVariant:
        m_fcVariant = readString(message.payload);
        emit identityChanged();
        break;
    case kMspFcVersion:
        m_fcVersion = readString(message.payload);
        emit identityChanged();
        break;
    case kMspBoardInfo:
        m_boardIdentifier = readString(message.payload.left(4));
        emit identityChanged();
        break;
    case kMspStatus:
        if (message.payload.size() >= 12)
            m_armingFlags = readS32(message.payload, 8);
        emit telemetryChanged();
        break;
    case kMspAttitude:
        if (message.payload.size() >= 6) {
            m_roll = readS16(message.payload, 0);
            m_pitch = readS16(message.payload, 2);
            m_yaw = readS16(message.payload, 4);
        }
        emit telemetryChanged();
        break;
    case kMspAltitude:
        if (message.payload.size() >= 4)
            m_altitude = readS32(message.payload, 0);
        emit telemetryChanged();
        break;
    case kMspAnalog:
        if (message.payload.size() >= 1) m_batteryVoltage = static_cast<quint8>(message.payload.at(0));
        if (message.payload.size() >= 2) m_batteryCurrent = readU16(message.payload, 1);
        if (message.payload.size() >= 3) m_batteryRemaining = static_cast<quint8>(message.payload.at(2));
        emit telemetryChanged();
        break;
    case kMspRc:
        m_rcChannels.clear();
        for (int offset = 0; offset + 1 < message.payload.size(); offset += 2)
            m_rcChannels.append(readU16(message.payload, offset));
        emit receiverChanged();
        break;
    case kMspServo:
        m_servoOutputs.clear();
        for (int offset = 0; offset + 1 < message.payload.size(); offset += 2)
            m_servoOutputs.append(readU16(message.payload, offset));
        emit outputsChanged();
        break;
    case kMspMotor:
        m_motorOutputs.clear();
        for (int offset = 0; offset + 1 < message.payload.size(); offset += 2)
            m_motorOutputs.append(readU16(message.payload, offset));
        emit outputsChanged();
        break;
    case kMspBoxNames:
        m_modeNames = readNullSeparatedStrings(message.payload);
        emit modesChanged();
        break;
    case kMspBoxIds:
        m_modeIds.clear();
        for (const auto byte : message.payload)
            m_modeIds.append(static_cast<quint8>(byte));
        emit modesChanged();
        break;
    case kMspPid:
        if (message.payload.size() >= 9) {
            m_pidPayload = message.payload;
            m_pidValues.clear();
            m_pidValues.reserve(m_pidPayload.size());
            for (const auto byte : m_pidPayload)
                m_pidValues.append(static_cast<quint8>(byte));
            emit pidChanged();
        } else {
            emit protocolError(QStringLiteral("The flight controller returned an incomplete PID profile."));
        }
        break;
    default:
        break;
    }
}

void MSPManager::onTimeout()
{
    if (!m_waiting)
        return;

    const auto command = m_lastCommand;
    m_waiting = false;
    emit waitingChanged();
    emit requestTimedOut(command);
}

} // namespace IndigenousGCS
