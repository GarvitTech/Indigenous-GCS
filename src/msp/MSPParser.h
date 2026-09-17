#pragma once

#include <QByteArray>
#include <QObject>

namespace IndigenousGCS {

struct MSPMessage
{
    quint8 command = 0;
    QByteArray payload;
};

class MSPParser : public QObject
{
    Q_OBJECT

public:
    explicit MSPParser(QObject *parent = nullptr);

    void parseBytes(const QByteArray &data);
    static QByteArray encodeRequest(quint8 command, const QByteArray &payload = {});

    quint64 totalReceived() const { return m_totalReceived; }
    quint64 totalDropped() const { return m_totalDropped; }

signals:
    void messageReceived(const IndigenousGCS::MSPMessage &message);

private:
    QByteArray m_buffer;
    quint64 m_totalReceived = 0;
    quint64 m_totalDropped = 0;
};

} // namespace IndigenousGCS

Q_DECLARE_METATYPE(IndigenousGCS::MSPMessage)
