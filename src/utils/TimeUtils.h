#pragma once
#include <QDateTime>
#include <QString>

namespace IndigenousGCS::TimeUtils {

// Current UTC timestamp as ISO 8601 string.
QString utcNowString();

// Elapsed milliseconds since a reference QDateTime.
qint64 elapsedMs(const QDateTime &since);

// Format a duration in milliseconds as "HH:MM:SS".
QString formatDuration(qint64 ms);

} // namespace IndigenousGCS::TimeUtils
