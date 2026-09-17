#include "MSPParser.h"

namespace IndigenousGCS {

MSPParser::MSPParser(QObject *parent)
    : QObject(parent)
{
    qRegisterMetaType<MSPMessage>();
}

QByteArray MSPParser::encodeRequest(quint8 command, const QByteArray &payload)
{
    const auto size = static_cast<quint8>(payload.size());
    QByteArray frame("$M<", 3);
    frame.append(static_cast<char>(size));
    frame.append(static_cast<char>(command));
    frame.append(payload);

    quint8 checksum = size ^ command;
    for (const auto byte : payload)
        checksum ^= static_cast<quint8>(byte);
    frame.append(static_cast<char>(checksum));
    return frame;
}

void MSPParser::parseBytes(const QByteArray &data)
{
    m_buffer.append(data);

    while (true) {
        int start = -1;
        for (const char direction : {'<', '>', '!'}) {
            const auto candidate = m_buffer.indexOf(QByteArray("$M") + direction);
            if (candidate >= 0 && (start < 0 || candidate < start))
                start = candidate;
        }
        if (start < 0) {
            m_totalDropped += static_cast<quint64>(m_buffer.size());
            m_buffer.clear();
            return;
        }
        if (start > 0) {
            m_totalDropped += static_cast<quint64>(start);
            m_buffer.remove(0, start);
        }
        if (m_buffer.size() < 6)
            return;

        const auto payloadSize = static_cast<quint8>(m_buffer.at(3));
        const auto frameSize = 6 + payloadSize;
        if (m_buffer.size() < frameSize)
            return;

        quint8 checksum = payloadSize ^ static_cast<quint8>(m_buffer.at(4));
        for (int index = 0; index < payloadSize; ++index)
            checksum ^= static_cast<quint8>(m_buffer.at(5 + index));

        if (checksum != static_cast<quint8>(m_buffer.at(frameSize - 1))) {
            ++m_totalDropped;
            m_buffer.remove(0, frameSize);
            continue;
        }

        MSPMessage message;
        message.command = static_cast<quint8>(m_buffer.at(4));
        message.payload = m_buffer.mid(5, payloadSize);
        m_buffer.remove(0, frameSize);
        ++m_totalReceived;
        emit messageReceived(message);
    }
}

} // namespace IndigenousGCS
