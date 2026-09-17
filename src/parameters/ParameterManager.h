#pragma once
#include <QObject>
#include <QHash>
#include <QTimer>
#include <memory>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"
#include "Parameter.h"

namespace IndigenousGCS {

class MAVLinkManager;

class ParameterManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int  totalCount    READ totalCount    NOTIFY parametersChanged)
    Q_PROPERTY(int  receivedCount READ receivedCount NOTIFY parametersChanged)
    Q_PROPERTY(bool loading       READ loading       NOTIFY loadingChanged)

public:
    explicit ParameterManager(MAVLinkManager *mavlink, QObject *parent = nullptr);

    int  totalCount()    const { return m_totalCount; }
    int  receivedCount() const { return m_params.size(); }
    bool loading()       const { return m_loading; }

    Q_INVOKABLE void requestAll(uint8_t targetSys, uint8_t targetComp);
    Q_INVOKABLE void setParameter(uint8_t targetSys, uint8_t targetComp,
                                  const QString &name, float value);
    Q_INVOKABLE QVariant getParameter(const QString &name) const;
    Q_INVOKABLE QStringList parameterNames() const;

    const QHash<QString, Parameter> &parameters() const { return m_params; }

public slots:
    void handleMessage(const mavlink_message_t &msg);

signals:
    void parametersChanged();
    void loadingChanged();
    void parameterUpdated(const QString &name);

private:
    void handleParamValue(const mavlink_message_t &msg);

    MAVLinkManager          *m_mavlink;
    QHash<QString, Parameter> m_params;
    int                       m_totalCount = 0;
    bool                      m_loading    = false;
};

} // namespace IndigenousGCS
