#include "SerialConnection.h"
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcSerial, "igcs.serial")

namespace IndigenousGCS {

SerialConnection::SerialConnection(QObject *parent) : Connection(parent)
{
    connect(&m_serial, &QSerialPort::readyRead,
            this, &SerialConnection::onReadyRead);
    connect(&m_serial, &QSerialPort::errorOccurred,
            this, &SerialConnection::onErrorOccurred);
}

void SerialConnection::setPortName(const QString &port)
{
    m_serial.setPortName(port);
}

void SerialConnection::setBaudRate(qint32 baud)
{
    m_serial.setBaudRate(baud);
}

bool SerialConnection::open()
{
    if (m_serial.portName().isEmpty()) {
        emit errorOccurred("No serial port configured");
        return false;
    }

    m_state = ConnectionState::Connecting;
    emit stateChanged(m_state);

    m_serial.setDataBits(QSerialPort::Data8);
    m_serial.setParity(QSerialPort::NoParity);
    m_serial.setStopBits(QSerialPort::OneStop);
    m_serial.setFlowControl(QSerialPort::NoFlowControl);

    if (!m_serial.open(QIODevice::ReadWrite)) {
        m_state = ConnectionState::Error;
        emit stateChanged(m_state);
        emit errorOccurred(m_serial.errorString());
        qCWarning(lcSerial) << "Failed to open" << m_serial.portName() << m_serial.errorString();
        return false;
    }

    m_state = ConnectionState::Connected;
    emit stateChanged(m_state);
    qCInfo(lcSerial) << "Opened" << m_serial.portName() << "at" << m_serial.baudRate();
    return true;
}

void SerialConnection::close()
{
    if (m_serial.isOpen())
        m_serial.close();
    m_state = ConnectionState::Disconnected;
    emit stateChanged(m_state);
}

bool SerialConnection::isOpen() const
{
    return m_serial.isOpen();
}

QString SerialConnection::description() const
{
    return QString("Serial: %1 @ %2").arg(m_serial.portName()).arg(m_serial.baudRate());
}

void SerialConnection::sendBytes(const QByteArray &data)
{
    if (!m_serial.isOpen()) return;
    m_serial.write(data);
}

void SerialConnection::onReadyRead()
{
    const QByteArray data = m_serial.readAll();
    if (!data.isEmpty())
        emit bytesReceived(data);
}

void SerialConnection::onErrorOccurred(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError) return;

    qCWarning(lcSerial) << "Serial error:" << m_serial.errorString();

    if (error == QSerialPort::ResourceError || error == QSerialPort::DeviceNotFoundError) {
        m_state = ConnectionState::Error;
        emit stateChanged(m_state);
    }
    emit errorOccurred(m_serial.errorString());
}

} // namespace IndigenousGCS
