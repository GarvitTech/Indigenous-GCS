#include "LogPaths.h"

#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcLogPaths, "igcs.logpaths")

namespace IndigenousGCS
{
    namespace LogPaths
    {

        QString dataDirectory()
        {
            // AppDataLocation resolves per platform:
            //   macOS   ~/Library/Application Support/<org>/<app>
            //   Windows %LOCALAPPDATA%/<org>/<app>
            //   Linux   ~/.local/share/<org>/<app>
            const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
            if (base.isEmpty())
            {
                qCWarning(lcLogPaths) << "No writable application data location is available";
                return QString();
            }

            QDir dir(base);
            if (!dir.exists() && !dir.mkpath(QStringLiteral(".")))
            {
                qCWarning(lcLogPaths) << "Cannot create log directory:" << base;
                return QString();
            }
            return base;
        }

        QString databasePath()
        {
            const QString dir = dataDirectory();
            if (dir.isEmpty())
                return QString();
            return QDir(dir).filePath(QStringLiteral("flightlogs.db"));
        }

        bool isWritable()
        {
            const QString dir = dataDirectory();
            if (dir.isEmpty())
                return false;
            const QFileInfo info(dir);
            return info.isDir() && info.isWritable();
        }

    } // namespace LogPaths
} // namespace IndigenousGCS
