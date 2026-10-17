#include "CommandTracker.h"

#include <QLoggingCategory>
#include "mavlink/mavlink.h"

Q_LOGGING_CATEGORY(lcCmdTracker, "igcs.command")

namespace IndigenousGCS
{

    CommandTracker::CommandTracker(QObject *parent)
        : QObject(parent)
    {
    }

    CommandTracker::~CommandTracker() = default;

    void CommandTracker::addCommand(uint16_t command, const QString &description, int timeoutMs)
    {
        // Replace any previous outstanding entry for the same command so the timer
        // cannot outlive its payload.
        auto it = m_pending.find(command);
        if (it != m_pending.end())
        {
            it.value().timer->stop();
            it.value().timer->deleteLater();
            m_pending.erase(it);
        }

        auto *timer = new QTimer(this);
        timer->setSingleShot(true);
        timer->setInterval(timeoutMs);

        Pending p;
        p.description = description;
        p.timer = timer;
        m_pending.insert(command, p);
        m_sentAt[command].start();

        connect(timer, &QTimer::timeout, this, [this, command]()
                { expire(command); });

        timer->start();
        qCDebug(lcCmdTracker) << "Tracking cmd" << command << ":" << description;
    }

    bool CommandTracker::handleAck(uint16_t command, uint8_t result)
    {
        auto it = m_pending.find(command);
        if (it == m_pending.end())
            return false;

        const QString desc = it.value().description;
        it.value().timer->stop();
        it.value().timer->deleteLater();
        m_pending.erase(it);

        const qint64 elapsed = m_sentAt.contains(command) ? m_sentAt[command].elapsed() : -1;
        m_sentAt.remove(command);

        if (result == MAV_RESULT_ACCEPTED)
        {
            qCInfo(lcCmdTracker) << "cmd" << command << "ACCEPTED in" << elapsed << "ms";
            emit commandSuccess(desc);
        }
        else
        {
            // Distinguish the common rejection reasons so the operator sees why.
            QString reason;
            switch (result)
            {
            case MAV_RESULT_TEMPORARILY_REJECTED:
                reason = tr("%1 rejected: temporarily rejected (try again)").arg(desc);
                break;
            case MAV_RESULT_DENIED:
                reason = tr("%1 denied by flight controller").arg(desc);
                break;
            case MAV_RESULT_UNSUPPORTED:
                reason = tr("%1 not supported by connected firmware").arg(desc);
                break;
            case MAV_RESULT_FAILED:
                reason = tr("%1 failed (pre-arm check?)").arg(desc);
                break;
            case MAV_RESULT_IN_PROGRESS:
                reason = tr("%1 in progress").arg(desc);
                break;
            default:
                reason = tr("%1 failed with result %2").arg(desc).arg(result);
                break;
            }
            qCWarning(lcCmdTracker) << reason;
            emit commandFailed(reason);
        }
        return true;
    }

    void CommandTracker::expire(uint16_t command)
    {
        auto it = m_pending.find(command);
        if (it == m_pending.end())
            return;

        const QString desc = it.value().description;
        it.value().timer->deleteLater();
        m_pending.erase(it);
        m_sentAt.remove(command);

        // A missing ACK is a real failure — surface it rather than silently
        // dropping it, otherwise the operator believes the command took effect.
        const QString reason = tr("%1 timed out — no acknowledgement from vehicle").arg(desc);
        qCWarning(lcCmdTracker) << reason;
        emit commandFailed(reason);
    }

    bool CommandTracker::isPending(uint16_t command) const
    {
        return m_pending.contains(command);
    }

    QString CommandTracker::description(uint16_t command) const
    {
        auto it = m_pending.constFind(command);
        return it == m_pending.constEnd() ? QString{} : it.value().description;
    }

} // namespace IndigenousGCS