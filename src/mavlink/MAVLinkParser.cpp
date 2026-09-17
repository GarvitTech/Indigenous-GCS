#include "MAVLinkParser.h"

namespace IndigenousGCS {

MAVLinkParser::MAVLinkParser(QObject *parent) : QObject(parent)
{
    memset(&m_message, 0, sizeof(m_message));
    memset(&m_status,  0, sizeof(m_status));
}

void MAVLinkParser::parseBytes(const QByteArray &data)
{
    for (int i = 0; i < data.size(); ++i) {
        const uint8_t byte = static_cast<uint8_t>(data[i]);
        if (mavlink_parse_char(MAVLINK_COMM_0, byte, &m_message, &m_status)) {
            ++m_totalReceived;
            emit messageReceived(m_message);
        }
    }
    m_totalDropped += m_status.packet_rx_drop_count;
    // Reset drop counter so we accumulate correctly
    m_status.packet_rx_drop_count = 0;
}

} // namespace IndigenousGCS
