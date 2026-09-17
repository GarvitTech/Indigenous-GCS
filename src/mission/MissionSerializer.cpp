#include "MissionSerializer.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

namespace IndigenousGCS {

QString MissionSerializer::s_lastError;

bool MissionSerializer::saveToFile(const Mission &mission, const QString &filePath)
{
    QJsonArray items;
    for (const Waypoint &wp : mission.waypoints()) {
        QJsonObject obj;
        obj["seq"]          = wp.seq;
        obj["command"]      = wp.command;
        obj["frame"]        = wp.frame;
        obj["autoContinue"] = wp.autoContinue;
        obj["latitude"]     = wp.latitude;
        obj["longitude"]    = wp.longitude;
        obj["altitude"]     = static_cast<double>(wp.altitude);
        obj["param1"]       = static_cast<double>(wp.param1);
        obj["param2"]       = static_cast<double>(wp.param2);
        obj["param3"]       = static_cast<double>(wp.param3);
        obj["param4"]       = static_cast<double>(wp.param4);
        items.append(obj);
    }

    QJsonObject root;
    root["version"]   = 1;
    root["name"]      = mission.name();
    root["waypoints"] = items;

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        s_lastError = file.errorString();
        return false;
    }
    file.write(QJsonDocument(root).toJson());
    return true;
}

bool MissionSerializer::loadFromFile(Mission &mission, const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        s_lastError = file.errorString();
        return false;
    }

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    if (err.error != QJsonParseError::NoError) {
        s_lastError = err.errorString();
        return false;
    }

    const QJsonObject root = doc.object();
    mission.setName(root["name"].toString("Mission"));

    QList<Waypoint> wps;
    for (const QJsonValue &v : root["waypoints"].toArray()) {
        const QJsonObject obj = v.toObject();
        Waypoint wp;
        wp.seq          = static_cast<uint16_t>(obj["seq"].toInt());
        wp.command      = static_cast<uint16_t>(obj["command"].toInt(MAV_CMD_NAV_WAYPOINT));
        wp.frame        = static_cast<uint8_t>(obj["frame"].toInt(MAV_FRAME_GLOBAL_RELATIVE_ALT));
        wp.autoContinue = obj["autoContinue"].toBool(true);
        wp.latitude     = obj["latitude"].toDouble();
        wp.longitude    = obj["longitude"].toDouble();
        wp.altitude     = static_cast<float>(obj["altitude"].toDouble(10.0));
        wp.param1       = static_cast<float>(obj["param1"].toDouble());
        wp.param2       = static_cast<float>(obj["param2"].toDouble(2.0));
        wp.param3       = static_cast<float>(obj["param3"].toDouble());
        wp.param4       = static_cast<float>(obj["param4"].toDouble());
        wps.append(wp);
    }
    mission.setWaypoints(wps);
    return true;
}

QString MissionSerializer::lastError() { return s_lastError; }

} // namespace IndigenousGCS
