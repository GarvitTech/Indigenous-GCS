#pragma once
#include <QObject>
#include <QByteArray>
#include <QStringList>
#include <QVariantList>
#include <memory>
#include "Connection.h"

namespace IndigenousGCS {

class SerialConnection;
class UDPConnection;

class ConnectionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ConnectionState connectionState READ connectionState NOTIFY connectionStateChanged)
    Q_PROPERTY(QString         description     READ description     NOTIFY connectionStateChanged)

public:
    explicit ConnectionManager(QObject *parent = nullptr);

    ConnectionState connectionState() const;
    QString         description() const;
    bool            isConnected() const;

    Q_INVOKABLE QVariantList availableSerialPorts() const;
    Q_INVOKABLE QStringList  supportedBaudRates() const;

    Q_INVOKABLE bool connectSerial(const QString &port, int baud);
    Q_INVOKABLE bool connectUDP(const QString &host, int port);
    Q_INVOKABLE void disconnect();

public slots:
    void sendBytes(const QByteArray &data);

signals:
    void bytesReceived(const QByteArray &data);
    void connectionStateChanged(ConnectionState state);
    void errorOccurred(const QString &message);

private:
    void setActiveConnection(std::unique_ptr<Connection> conn);
    void onStateChanged(ConnectionState state);

    std::unique_ptr<Connection> m_connection;
};

} // namespace IndigenousGCS
