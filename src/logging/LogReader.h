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

private:
    QSqlDatabase m_db;
};

} // namespace IndigenousGCS
