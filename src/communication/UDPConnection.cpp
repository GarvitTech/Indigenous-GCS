#include "UDPConnection.h"
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcUDP, "igcs.udp")

namespace IndigenousGCS {

UDPConnection::UDPConnection(QObject *parent) : Connection(parent)
{
    connect(&m_socket, &QUdpSocket::readyRead, this, &UDPConnection::onReadyRead);
}

void UDPConnection::setListenPort(quint16 port)
{
    m_listenPort = port;
}

void UDPConnection::setTargetHost(const QString &host, quint16 port)
{
    m_targetHost = QHostAddress(host);
    m_targetPort = port;
}

bool UDPConnection::open()
{
    m_state = ConnectionState::Connecting;
    emit stateChanged(m_state);

    if (!m_socket.bind(QHostAddress::AnyIPv4, m_listenPort)) {
        m_state = ConnectionState::Error;
        emit stateChanged(m_state);
        emit errorOccurred(m_socket.errorString());
        qCWarning(lcUDP) << "UDP bind failed:" << m_socket.errorString();
        return false;
    }

    m_state = ConnectionState::Connected;
    emit stateChanged(m_state);
    qCInfo(lcUDP) << "UDP listening on port" << m_listenPort;
    return true;
}

void UDPConnection::close()
{
    m_socket.close();
    m_state = ConnectionState::Disconnected;
    emit stateChanged(m_state);
}

bool UDPConnection::isOpen() const
{
    return m_socket.state() == QAbstractSocket::BoundState;
}

QString UDPConnection::description() const
{
    return QString("UDP: 0.0.0.0:%1 → %2:%3")
        .arg(m_listenPort)
        .arg(m_targetHost.toString())
        .arg(m_targetPort);
}

void UDPConnection::sendBytes(const QByteArray &data)
{
    if (!isOpen()) return;
    m_socket.writeDatagram(data, m_targetHost, m_targetPort);
}

void UDPConnection::onReadyRead()
{
    while (m_socket.hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(static_cast<int>(m_socket.pendingDatagramSize()));
        QHostAddress sender;
        quint16 senderPort;
        m_socket.readDatagram(datagram.data(), datagram.size(), &sender, &senderPort);

        // Auto-configure target to reply to whoever sent us data
        m_targetHost = sender;
        m_targetPort = senderPort;

        if (!datagram.isEmpty())
            emit bytesReceived(datagram);
    }
}

} // namespace IndigenousGCS
