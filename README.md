# Indigenous GCS

**Cross-platform Ground Control Station for Indigenous ESP32 Flight Controllers**

A production-quality, modular GCS built with C++17, Qt 6, QML, and MAVLink 2.

Themed for **Indian Air Force / NCC aerospace** use — a deep strategic-navy avionics
palette with saffron (kesari) accents and a subtle tricolor identity bar.

---

## Features

- Real MAVLink 2 communication (Serial + UDP)
- Live telemetry dashboard (attitude, GPS, battery, speed, mode)
- Artificial horizon, compass, HUD
- Mission planner with upload/download
- Parameter manager with live editing
- Calibration framework (accel, gyro, mag, level, RC, ESC)
- Safety monitoring with severity alerts
- Flight logging to SQLite
- Built-in simulator (no hardware required)
- Diagnostics and MAVLink inspector
- Firmware info (OTA architecture documented)
- Dark aerospace UI, responsive from 1280×720 upward

---

## Architecture

```
IndigenousGCS/
├── src/
│   ├── app/           Application, AppSettings
│   ├── communication/ Connection, SerialConnection, UDPConnection, ConnectionManager
│   ├── mavlink/       MAVLinkParser, MAVLinkSender, MAVLinkManager
│   ├── vehicle/       Vehicle, VehicleState, Telemetry, FlightModeManager, VehicleManager
│   ├── mission/       Waypoint, Mission, MissionManager, MissionSerializer
│   ├── parameters/    Parameter, ParameterManager
│   ├── calibration/   CalibrationManager
│   ├── safety/        SafetyManager, FailsafeManager
│   ├── logging/       FlightLogger, LogReader
│   ├── firmware/      FirmwareManager
│   ├── simulation/    Simulator
│   └── utils/         GeoUtils, Units, TimeUtils
├── qml/
│   ├── pages/         Dashboard, FlightData, MissionPlanner, Parameters, ...
│   ├── components/    TopBar, SideBar, StatusBar, ArtificialHorizon, Compass, ...
│   └── theme/         Colors, Theme
├── mavlink/           MAVLink C library headers (common dialect)
├── tests/             Unit tests for all subsystems
└── docs/              Architecture, MAVLink, ESP32 integration, build guides
```

---

## Requirements

| Dependency | Version  |
|------------|----------|
| Qt         | 6.5+     |
| CMake      | 3.21+    |
| C++        | 17       |
| Compiler   | MSVC 2022 / Clang 14+ / GCC 11+ |

---

## Build

### macOS
```bash
brew install cmake qt@6
export CMAKE_PREFIX_PATH=$(brew --prefix qt@6)
cd IndigenousGCS
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(sysctl -n hw.ncpu)
```

### Windows
```cmd
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.x.x/msvc2022_64"
cmake --build build --config Release
```

See `docs/build-macos.md` and `docs/build-windows.md` for full instructions.

---

## Running

```bash
./build/bin/IndigenousGCS
```

### Quick Start with Simulator
1. Launch the app
2. Go to **Simulation** page
3. Click **START SIM**
4. Click **ARM** → **TAKEOFF**
5. Watch live telemetry on **Dashboard** and **Flight Data**

### Connecting to Real ESP32
1. Flash MAVLink firmware to ESP32 (see `docs/esp32-integration.md`)
2. Connect USB serial
3. Go to **Diagnostics** → enter port and baud rate → **CONNECT**
4. Vehicle appears automatically when heartbeat is received

---

## MAVLink Configuration

- GCS System ID: 255 (configurable in settings)
- GCS Component ID: 190
- Default UDP port: 14550
- Default baud rates: 57600, 115200, 230400, 460800, 921600

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No vehicle detected | Check baud rate, verify ESP32 sends HEARTBEAT |
| Parameters not loading | Ensure FC implements PARAM_REQUEST_LIST |
| Mission upload fails | Check FC implements MISSION_REQUEST_INT |
| Simulator not working | Click START SIM before ARM |

---

## Development

```bash
# Run tests
cd build && ctest --output-on-failure

# Enable debug logging
export QT_LOGGING_RULES="igcs.*=true"
```

See `docs/architecture.md` for subsystem design details.
