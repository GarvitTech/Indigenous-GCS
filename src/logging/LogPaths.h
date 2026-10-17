#pragma once

#include <QString>

namespace IndigenousGCS
{

    /**
     * Single source of truth for the flight-log database location.
     *
     * FlightLogger writes to this database and LogReader reads from it. They must
     * agree on the path or recordings become invisible — which is exactly what
     * happened when each class built its own path and they silently diverged
     * (`logs.db` vs `flightlogs.db`).
     *
     * The directory is created on demand. Callers should treat a failure to create
     * it as fatal for logging and surface the reason rather than writing nowhere.
     */
    namespace LogPaths
    {

        /// Absolute path to the flight-log SQLite database.
        QString databasePath();

        /// Absolute path to the directory holding the database. Created if missing.
        QString dataDirectory();

        /// True when the directory exists and is writable.
        bool isWritable();

    } // namespace LogPaths

} // namespace IndigenousGCS
