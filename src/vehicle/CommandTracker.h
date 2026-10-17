#pragma once

#include <QObject>
#include <QString>
#include <QHash>
#include <QTimer>
#include <QElapsedTimer>
#include <cstdint>

namespace IndigenousGCS
{

    /**
     * Tracks outbound MAVLink commands and matches them against COMMAND_ACK.
     *
     * A GCS must never assume a command succeeded. Every command sent to the
     * flight controller is registered here, then either acknowledged or timed
     * out — the UI reflects the real outcome, not an optimistic guess.
     */
    class CommandTracker : public QObject
    {
        Q_OBJECT
    public:
        explicit CommandTracker(QObject *parent = nullptr);
        ~CommandTracker() override;

        /// Register a command awaiting acknowledgement.
        void addCommand(uint16_t command, const QString &description, int timeoutMs = 5000);

        /// Feed a COMMAND_ACK. Returns true if the command was being tracked.
        bool handleAck(uint16_t command, uint8_t result);

        /// True while a command is outstanding.
        bool isPending(uint16_t command) const;

        /// Human-readable description for a tracked command, empty if not tracked.
        QString description(uint16_t command) const;

    signals:
        void commandSuccess(const QString &description);
        void commandFailed(const QString &reason);

    private:
        struct Pending
        {
            QString description;
            QTimer *timer = nullptr;
        };

        void expire(uint16_t command);

        QHash<uint16_t, Pending> m_pending;
        QHash<uint16_t, QElapsedTimer> m_sentAt;
    };

} // namespace IndigenousGCS