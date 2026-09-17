#pragma once
#include <QObject>
#include <QByteArray>

// MAVLink C library
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"

namespace IndigenousGCS {

class MAVLinkParser : public QObject
{
    Q_OBJECT
public:
    explicit MAVLinkParser(QObject *parent = nullptr);

    // Feed raw bytes; emits messageReceived for each complete, valid message.
    void parseBytes(const QByteArray &data);

    quint64 totalReceived() const { return m_totalReceived; }
    quint64 totalDropped()  const { return m_totalDropped; }

signals:
    void messageReceived(const mavlink_message_t &msg);

private:
    mavlink_message_t  m_message{};
    mavlink_status_t   m_status{};
    quint64            m_totalReceived = 0;
    quint64            m_totalDropped  = 0;
};

} // namespace IndigenousGCS
