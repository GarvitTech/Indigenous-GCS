#pragma once
#include "Connection.h"
#include <QUdpSocket>
#include <QHostAddress>

namespace IndigenousGCS {

class UDPConnection : public Connection
{
    Q_OBJECT
public:
    explicit UDPConnection(QObject *parent = nullptr);

    void setListenPort(quint16 port);
    void setTargetHost(const QString &host, quint16 port);

    bool        open()  override;
    void        close() override;
    bool        isOpen() const override;
    QString     description() const override;
    ConnectionState state() const override { return m_state; }

public slots:
    void sendBytes(const QByteArray &data) override;

private slots:
    void onReadyRead();

private:
    QUdpSocket      m_socket;
    quint16         m_listenPort  = 14550;
    QHostAddress    m_targetHost  = QHostAddress::LocalHost;
    quint16         m_targetPort  = 14550;
    ConnectionState m_state       = ConnectionState::Disconnected;
};

} // namespace IndigenousGCS
