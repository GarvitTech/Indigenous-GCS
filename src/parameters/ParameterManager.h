#pragma once
#include <QObject>
#include <QHash>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <memory>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"
#include "Parameter.h"

namespace IndigenousGCS {

class MAVLinkManager;

class ParameterManager : public QObject
{
    Q_OBJECT
    // New API property names
    Q_PROPERTY(int  totalParameters    READ totalParameters    NOTIFY parametersChanged)
    Q_PROPERTY(int  receivedParameters READ receivedParameters NOTIFY parametersChanged)
    Q_PROPERTY(bool isDownloading      READ isDownloading      NOTIFY isDownloadingChanged)

    // Legacy property names (kept for QML backward compat)
    Q_PROPERTY(int  totalCount         READ totalCount         NOTIFY parametersChanged)
    Q_PROPERTY(int  receivedCount      READ receivedCount      NOTIFY parametersChanged)
    Q_PROPERTY(bool loading            READ isDownloading      NOTIFY isDownloadingChanged)

public:
    explicit ParameterManager(MAVLinkManager *mavlink, QObject *parent = nullptr);

    // New API
    int  totalParameters()    const { return m_totalCount; }
    int  receivedParameters() const { return m_params.size(); }
    bool isDownloading()      const { return m_loading; }

    // Legacy API aliases
    int  totalCount()         const { return m_totalCount; }
    int  receivedCount()      const { return m_params.size(); }
    bool loading()            const { return m_loading; }

    // New QML-friendly API
    Q_INVOKABLE void requestAllParameters();
    Q_INVOKABLE bool setParameter(const QString &name, double value);
    Q_INVOKABLE QVariantList getParameters() const;
    Q_INVOKABLE void exportParameters(const QString &filePath);
    Q_INVOKABLE void importParameters(const QString &filePath);

    // Legacy API (kept for backward compat)
    Q_INVOKABLE void requestAll(uint8_t targetSys, uint8_t targetComp);
    Q_INVOKABLE void setParameterRaw(uint8_t targetSys, uint8_t targetComp,
                                     const QString &name, float value);
    Q_INVOKABLE QVariant getParameter(const QString &name) const;
    Q_INVOKABLE QStringList parameterNames() const;

    const QHash<QString, Parameter> &parameters() const { return m_params; }

    // Set the target vehicle sysId/compId for new-style API
    void setTarget(uint8_t sysId, uint8_t compId) {
        m_targetSys  = sysId;
        m_targetComp = compId;
    }

public slots:
    void handleMessage(const mavlink_message_t &msg);

signals:
    void parametersChanged();
    void isDownloadingChanged();
    void loadingChanged();          // legacy alias
    void parameterUpdated(const QString &name);
    void downloadProgress(int received, int total);

private:
    void handleParamValue(const mavlink_message_t &msg);

    MAVLinkManager            *m_mavlink;
    QHash<QString, Parameter>  m_params;
    int                        m_totalCount  = 0;
    bool                       m_loading     = false;
    uint8_t                    m_targetSys   = 1;
    uint8_t                    m_targetComp  = 1;
};

} // namespace IndigenousGCS
