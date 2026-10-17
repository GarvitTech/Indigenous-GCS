#pragma once

#include "Connection.h"
#include <QByteArray>
#include <QString>

namespace IndigenousGCS
{

    /**
     * In-process loopback connection.
     *
     * Bytes written with sendBytes() are echoed straight back through
     * bytesReceived(). Combined with the Simulator this gives a complete
     * GCS -> transport -> MAVLink -> GCS path that exercises the real
     * parsing, dispatch and state code with no hardware and no network.
     */
    class VirtualConnection : public Connection
    {
        Q_OBJECT
    public:
        explicit VirtualConnection(QObject *parent = nullptr);

        bool open() override;
        void close() override;
        bool isOpen() const override { return m_open; }
        QString description() const override;
        ConnectionState state() const override;

    public slots:
        void sendBytes(const QByteArray &data) override;

    private:
        bool m_open = false;
    };

} // namespace IndigenousGCS