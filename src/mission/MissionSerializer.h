#pragma once
#include <QString>
#include "Mission.h"

namespace IndigenousGCS {

class MissionSerializer
{
public:
    static bool saveToFile(const Mission &mission, const QString &filePath);
    static bool loadFromFile(Mission &mission, const QString &filePath);
    static QString lastError();

private:
    static QString s_lastError;
};

} // namespace IndigenousGCS
