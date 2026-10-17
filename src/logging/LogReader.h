#pragma once
#include <QObject>
#include <QVariantList>
#include <QSqlDatabase>

namespace IndigenousGCS {

class LogReader : public QObject
{
    Q_OBJECT
public:
    explicit LogReader(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList listSessions() const;
    Q_INVOKABLE QVariantList readSession(qint64 sessionId) const;
    Q_INVOKABLE bool clearSessions();

    /// Write one session to a CSV file chosen by the caller. Returns true on
    /// success. The UI supplies the path so the operator controls the location.
    Q_INVOKABLE bool exportSession(qint64 sessionId, const QString &filePath) const;

    /// Suggested filename for a session, e.g. "IndigenousGCS-log-7-2026-10-17.csv".
    Q_INVOKABLE QString suggestedExportName(qint64 sessionId) const;

    /// True when the underlying database opened successfully.
    Q_INVOKABLE bool isAvailable() const { return m_db.isOpen(); }

    /// Absolute path of the database being read, for display in the UI.
    Q_INVOKABLE QString databasePath() const;

private:
    QSqlDatabase m_db;
};

} // namespace IndigenousGCS
