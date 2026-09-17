#pragma once
#include "Connection.h"
#include <QSerialPort>
#include <QTimer>

namespace IndigenousGCS {

class SerialConnection : public Connection
{
    Q_OBJECT
public:
    explicit SerialConnection(QObject *parent = nullptr);

    void setPortName(const QString &port);
    void setBaudRate(qint32 baud);

    bool        open()  override;
    void        close() override;
    bool        isOpen() const override;
    QString     description() const override;
    ConnectionState state() const override { return m_state; }

public slots:
    void sendBytes(const QByteArray &data) override;

private slots:
    void onReadyRead();
    void onErrorOccurred(QSerialPort::SerialPortError error);

private:
    QSerialPort     m_serial;
    ConnectionState m_state = ConnectionState::Disconnected;
};

} // namespace IndigenousGCS
