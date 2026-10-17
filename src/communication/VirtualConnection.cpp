#include "VirtualConnection.h"

#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcVirtualConn, "igcs.conn.virtual")

namespace IndigenousGCS
{

    VirtualConnection::VirtualConnection(QObject *parent)
        : Connection(parent)
    {
    }

    bool VirtualConnection::open()
    {
        if (m_open)
            return true;

        m_open = true;
        qCInfo(lcVirtualConn) << "Virtual loopback connection opened";
        emit stateChanged(ConnectionState::Connected);
        return true;
    }

    void VirtualConnection::close()
    {
        if (!m_open)
            return;

        m_open = false;
        qCInfo(lcVirtualConn) << "Virtual loopback connection closed";
        emit stateChanged(ConnectionState::Disconnected);
    }

    QString VirtualConnection::description() const
    {
        return tr("Virtual Loopback");
    }

    ConnectionState VirtualConnection::state() const
    {
        return m_open ? ConnectionState::Connected : ConnectionState::Disconnected;
    }

    void VirtualConnection::sendBytes(const QByteArray &data)
    {
        if (!m_open)
        {
            emit errorOccurred(tr("Cannot send on a closed virtual connection"));
            return;
        }

        // Echo synchronously. Queued delivery would be more faithful to a real
        // link, but synchronous echo keeps ordering deterministic for tests.
        if (!data.isEmpty())
            emit bytesReceived(data);
    }

} // namespace IndigenousGCS