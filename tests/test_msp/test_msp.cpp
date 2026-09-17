#include <QtTest>
#include <QSignalSpy>
#include "msp/MSPParser.h"

using IndigenousGCS::MSPMessage;
using IndigenousGCS::MSPParser;

class TestMSP : public QObject
{
    Q_OBJECT

private slots:
    void testEncodeRequest()
    {
        const auto frame = MSPParser::encodeRequest(10, QByteArray::fromHex("0102"));
        QCOMPARE(frame.toHex(), QByteArray("244d3c020a01020b"));
    }

    void testParseFragmentedFrame()
    {
        MSPParser parser;
        QSignalSpy messages(&parser, &MSPParser::messageReceived);
        const auto frame = MSPParser::encodeRequest(101, QByteArray::fromHex("3412"));

        parser.parseBytes(frame.left(3));
        QCOMPARE(messages.count(), 0);
        parser.parseBytes(frame.mid(3, 2));
        QCOMPARE(messages.count(), 0);
        parser.parseBytes(frame.mid(5));

        QCOMPARE(messages.count(), 1);
        const auto message = qvariant_cast<MSPMessage>(messages.at(0).at(0));
        QCOMPARE(message.command, quint8(101));
        QCOMPARE(message.payload, QByteArray::fromHex("3412"));
        QCOMPARE(parser.totalReceived(), quint64(1));
    }

    void testParseControllerResponse()
    {
        MSPParser parser;
        QSignalSpy messages(&parser, &MSPParser::messageReceived);
        auto frame = MSPParser::encodeRequest(108, QByteArray::fromHex("010002000300"));
        frame[2] = '>';

        parser.parseBytes(frame);

        QCOMPARE(messages.count(), 1);
        const auto message = qvariant_cast<MSPMessage>(messages.at(0).at(0));
        QCOMPARE(message.command, quint8(108));
        QCOMPARE(message.payload, QByteArray::fromHex("010002000300"));
    }

    void testRejectsBadChecksum()
    {
        MSPParser parser;
        QSignalSpy messages(&parser, &MSPParser::messageReceived);
        auto frame = MSPParser::encodeRequest(1);
        frame[frame.size() - 1] = static_cast<char>(frame.at(frame.size() - 1) ^ 0xff);

        parser.parseBytes(frame);

        QCOMPARE(messages.count(), 0);
        QCOMPARE(parser.totalReceived(), quint64(0));
        QCOMPARE(parser.totalDropped(), quint64(1));
    }
};

QTEST_MAIN(TestMSP)
#include "test_msp.moc"
