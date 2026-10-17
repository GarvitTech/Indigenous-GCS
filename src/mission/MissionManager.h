#pragma once
#include <QObject>
#include <QTimer>
#include <memory>
#define MAVLINK_USE_MESSAGE_INFO
#include "mavlink/mavlink.h"
#include "Mission.h"

namespace IndigenousGCS {

class MAVLinkManager;

enum class MissionTransferState {
    Idle,
    Uploading,
    Downloading,
    Complete,
    Failed,
    Clearing
};

class MissionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MissionTransferState transferState READ transferState NOTIFY transferStateChanged)
    Q_PROPERTY(int  transferProgress READ transferProgress NOTIFY transferProgressChanged)
    Q_PROPERTY(Mission* mission READ mission CONSTANT)

public:
    explicit MissionManager(MAVLinkManager *mavlink, QObject *parent = nullptr);

    Mission *mission() const { return m_mission.get(); }

    MissionTransferState transferState()    const { return m_transferState; }
    int                  transferProgress() const { return m_transferProgress; }

    Q_INVOKABLE void uploadMission(uint8_t targetSys, uint8_t targetComp);
    Q_INVOKABLE void downloadMission(uint8_t targetSys, uint8_t targetComp);
    Q_INVOKABLE void clearMission(uint8_t targetSys, uint8_t targetComp);

public slots:
    void handleMessage(const mavlink_message_t &msg);

signals:
    void transferStateChanged();
    void transferProgressChanged();
    void uploadComplete();
    void downloadComplete();
    void clearComplete();
    void transferFailed(const QString &reason);

private:
    void handleMissionRequest(const mavlink_message_t &msg);
    void handleMissionRequestInt(const mavlink_message_t &msg);
    void handleMissionAck(const mavlink_message_t &msg);
    void handleMissionCount(const mavlink_message_t &msg);
    void handleMissionItemInt(const mavlink_message_t &msg);
    void handleMissionItem(const mavlink_message_t &msg);
    void appendDownloadedWaypoint(const Waypoint &waypoint);
    void sendNextItem(bool useIntProtocol);
    void setState(MissionTransferState s);
    bool transferInProgress() const;
    bool isTargetMessage(const mavlink_message_t &msg) const;
    void onTimeout();

    MAVLinkManager              *m_mavlink;
    std::unique_ptr<Mission>     m_mission;
    MissionTransferState         m_transferState    = MissionTransferState::Idle;
    int                          m_transferProgress = 0;

    uint8_t  m_targetSys  = 0;
    uint8_t  m_targetComp = 0;
    uint16_t m_expectedCount = 0;
    uint16_t m_nextSeq       = 0;
    bool m_downloadUsesInt = false;
    QList<Waypoint> m_downloadBuffer;

    QTimer m_timeoutTimer;
    static constexpr int kTimeoutMs = 5000;
};

} // namespace IndigenousGCS
