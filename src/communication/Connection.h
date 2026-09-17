#pragma once
#include <QObject>
#include <QByteArray>
#include <QString>

namespace IndigenousGCS {

enum class ConnectionState {
    Disconnected,
    Connecting,
    Connected,
    Reconnecting,
    Error
};

class Connection : public QObject
{
    Q_OBJECT
public:
    explicit Connection(QObject *parent = nullptr) : QObject(parent) {}
    virtual ~Connection() = default;

    virtual bool        open()  = 0;
    virtual void        close() = 0;
    virtual bool        isOpen() const = 0;
    virtual QString     description() const = 0;
    virtual ConnectionState state() const = 0;

public slots:
    virtual void sendBytes(const QByteArray &data) = 0;

signals:
    void bytesReceived(const QByteArray &data);
    void stateChanged(ConnectionState state);
    void errorOccurred(const QString &message);
};

} // namespace IndigenousGCS
