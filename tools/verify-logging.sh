#!/usr/bin/env bash
#
# tools/verify-logging.sh
#
# Proves the flight-logging round trip works against the real classes, using the
# same call sequence the Logs page performs:
#
#     start -> log samples -> stop -> list -> read -> export
#
# Run after a build:   ./tools/verify-logging.sh
#
# This exists because the logging feature previously failed in a way that
# compiled cleanly and passed every other test — the writer and the reader used
# different database files, so recordings were written and never seen.
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"

TEST_BIN="$BUILD_DIR/bin/test_logging_integration"

if [[ ! -x "$TEST_BIN" ]]; then
    echo "ERROR: $TEST_BIN not found. Build first:" >&2
    echo "  cmake -S \"$PROJECT_DIR\" -B \"$BUILD_DIR\" && cmake --build \"$BUILD_DIR\"" >&2
    exit 1
fi

echo "==> Running the flight-logging integration test"
"$TEST_BIN"

DB="$HOME/Library/Application Support/IndigenousGCS/IndigenousGCS/flightlogs.db"
if [[ "$(uname)" != "Darwin" ]]; then
    # Windows: %LOCALAPPDATA%, Linux: XDG data dir. Only report if we can find it.
    DB="$(find "$HOME" -name flightlogs.db -path '*IndigenousGCS*' 2>/dev/null | head -1 || true)"
fi

if [[ -n "$DB" && -f "$DB" ]]; then
    echo
    echo "==> Database written by the test: $DB"
    if command -v sqlite3 >/dev/null 2>&1; then
        echo "    sessions : $(sqlite3 "$DB" 'SELECT COUNT(*) FROM sessions;')"
        echo "    rows     : $(sqlite3 "$DB" 'SELECT COUNT(*) FROM telemetry;')"
        echo
        echo "    most recent session:"
        sqlite3 "$DB" "SELECT '      id=' || id || '  label=' || label ||
                              '  rows=' || (SELECT COUNT(*) FROM telemetry t WHERE t.session_id = s.id)
                       FROM sessions s ORDER BY id DESC LIMIT 1;" || true
    else
        echo "    (install sqlite3 to see row counts)"
    fi
fi

echo
echo "==> Logging verification complete."
