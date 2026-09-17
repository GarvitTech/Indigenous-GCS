#include "TimeUtils.h"

namespace IndigenousGCS::TimeUtils {

QString utcNowString()
{
    return QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
}

qint64 elapsedMs(const QDateTime &since)
{
    return since.msecsTo(QDateTime::currentDateTimeUtc());
}

QString formatDuration(qint64 ms)
{
    qint64 totalSec = ms / 1000;
    int h = static_cast<int>(totalSec / 3600);
    int m = static_cast<int>((totalSec % 3600) / 60);
    int s = static_cast<int>(totalSec % 60);
    return QString("%1:%2:%3")
        .arg(h, 2, 10, QChar('0'))
        .arg(m, 2, 10, QChar('0'))
        .arg(s, 2, 10, QChar('0'));
}

} // namespace IndigenousGCS::TimeUtils
