#include "ConnectionManager.h"
#include "SerialConnection.h"
#include "UDPConnection.h"
#include <QSerialPortInfo>
#include <QVariantMap>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcConn, "igcs.connection")

namespace IndigenousGCS {

ConnectionManager::ConnectionManager(QObject *parent) : QObject(parent) {}

ConnectionState ConnectionManager::connectionState() const
{
    return m_connection ? m_connection->state() : ConnectionState::Disconnected;
}

QString ConnectionManager::description() const
{
    return m_connection ? m_connection->description() : "Not connected";
}

bool ConnectionManager::isConnected() const
{
    return m_connection && m_connection->isOpen();
}

QVariantList ConnectionManager::availableSerialPorts() const
{
    QVariantList result;
    for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts()) {
        QVariantMap entry;
        entry["portName"]     = info.portName();
        entry["description"]  = info.description();
        entry["manufacturer"] = info.manufacturer();
        entry["serialNumber"] = info.serialNumber();
        entry["vendorId"]     = info.hasVendorIdentifier()  ? QString::number(info.vendorIdentifier(),  16).toUpper() : "";
        entry["productId"]    = info.hasProductIdentifier() ? QString::number(info.productIdentifier(), 16).toUpper() : "";
        result.append(entry);
    }
    return result;
}

QStringList ConnectionManager::supportedBaudRates() const
{
    // Only rates that every platform actually supports are listed. Windows
    // rejects arbitrary baud values, so the UI must offer a known-good set
    // rather than letting the operator type an unsupported number.
    return { "57600", "115200", "230400", "460800", "921600" };
}

bool ConnectionManager::connectSerial(const QString &port, int baud)
{
    if (port.trimmed().isEmpty()) {
        emit errorOccurred(tr("No serial port selected."));
        return false;
    }
    if (baud <= 0) {
        emit errorOccurred(tr("Invalid baud rate: %1").arg(baud));
        return false;
    }

    disconnect();
    auto conn = std::make_unique<SerialConnection>(this);
    conn->setPortName(normalizePortName(port));
    conn->setBaudRate(static_cast<qint32>(baud));
    setActiveConnection(std::move(conn));
    return m_connection->open();
}

QString ConnectionManager::normalizePortName(const QString &port)
{
    const QString trimmed = port.trimmed();

#ifdef Q_OS_WIN
    // Windows requires the \\.\ prefix for COM ports numbered 10 and above;
    // without it, opening "COM10" fails with a file-not-found error even though
    // the port is present. Ports COM1..COM9 work either way, but using the
    // prefix consistently is harmless and removes a whole class of
    // "it works for COM3 but not COM12" reports.
    if (trimmed.startsWith(QStringLiteral("COM"), Qt::CaseInsensitive)
        && !trimmed.startsWith(QStringLiteral("\\\\.\\"))) {
        return QStringLiteral("\\\\.\\") + trimmed;
    }
#endif

    return trimmed;
}

bool ConnectionManager::connectUDP(const QString &host, int port)
{
    disconnect();
    auto conn = std::make_unique<UDPConnection>(this);
    conn->setListenPort(static_cast<quint16>(port));
    conn->setTargetHost(host, static_cast<quint16>(port));
    setActiveConnection(std::move(conn));
    return m_connection->open();
}

void ConnectionManager::disconnect()
{
    if (m_connection) {
        m_connection->close();
        m_connection.reset();
        emit connectionStateChanged(ConnectionState::Disconnected);
    }
}

void ConnectionManager::sendBytes(const QByteArray &data)
{
    if (m_connection)
        m_connection->sendBytes(data);
}

void ConnectionManager::setActiveConnection(std::unique_ptr<Connection> conn)
{
    m_connection = std::move(conn);
    connect(m_connection.get(), &Connection::bytesReceived,
            this, &ConnectionManager::bytesReceived);
    connect(m_connection.get(), &Connection::stateChanged,
            this, &ConnectionManager::onStateChanged);
    connect(m_connection.get(), &Connection::errorOccurred,
            this, &ConnectionManager::errorOccurred);
}

void ConnectionManager::onStateChanged(ConnectionState state)
{
    emit connectionStateChanged(state);
}

} // namespace IndigenousGCS
