# IndigenousGCS

**Cross-platform Ground Control Station for Indigenous ESP32 Flight Controllers**

[![Build – macOS](https://img.shields.io/badge/macOS-passing-brightgreen?logo=apple)](#build--macos)
[![Build – Windows](https://img.shields.io/badge/Windows-passing-brightgreen?logo=windows)](#build--windows)
[![Qt](https://img.shields.io/badge/Qt-6.5%2B-41CD52?logo=qt)](#requirements)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-blue?logo=cplusplus)](#requirements)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A production-quality, modular GCS built with **C++17**, **Qt 6**, **QML**, and
**MAVLink 2**. Themed for **Indian Air Force / NCC aerospace** use — a deep
strategic-navy avionics palette with saffron (kesari) accents and a subtle
tricolor identity bar.

---

## Screenshot

> _Dashboard with live telemetry, artificial horizon, compass, and HUD._
> _(Screenshot placeholder — run the simulator to see the full UI.)_

---

## Features

### Communication
- MAVLink 2 over Serial (USB / UART) and UDP
- Auto-detection of connected vehicles via heartbeat monitoring
- Virtual / simulator connection for offline use
- Configurable system ID, component ID, baud rate, and UDP port

### Flight Data & HUD
- Real-time telemetry: attitude, GPS fix, battery voltage/current, airspeed,
  altitude, groundspeed, flight mode, armed state
- Animated artificial horizon (roll + pitch) with realistic aircraft symbol
- Altitude tape with climb-rate indicator
- Compass rose with heading readout
- Full HUD overlay (FlightHud.qml) combining all primary flight instruments
- Battery, GPS lock, and connection-quality status indicators

### Mission Planner
- Interactive map (OpenStreetMap — no API key required)
- Click-to-place waypoints, drag-to-move, delete individual waypoints
- Mission upload to flight controller (MAVLink MISSION_COUNT / MISSION_ITEM_INT)
- Mission download from flight controller
- Clear FC mission (MISSION_CLEAR_ALL)
- Local validation before upload
- Route line display, vehicle centering, pan/zoom

### Parameters
- Download all parameters from flight controller (PARAM_REQUEST_LIST)
- Live edit and write individual parameters (PARAM_SET)
- Filter/search by name

### Calibration
- Accelerometer, gyroscope, magnetometer calibration
- Level horizon calibration
- RC channel calibration
- ESC calibration
- Progress and status feedback via MAVLink STATUSTEXT

### Safety & Failsafe
- Real-time safety monitoring with severity-level alerts (info / warning / error / critical)
- Failsafe manager with configurable thresholds
- Notification panel for in-app alerts

### INAV Configurator
- MSP protocol communication (for INAV/Betaflight targets)
- PID profile read / write / save
- Board info and sensor status

### Simulation
- Built-in physics simulator (no hardware required)
- Simulated attitude, GPS, battery, and speed telemetry
- ARM / TAKEOFF / LAND actions
- Clearly labeled as simulation; cannot trigger hardware calibration/upload

### Logging
- Flight log recording to SQLite database
- Log session browser and viewer
- Export log data

### Diagnostics
- MAVLink packet inspector and statistics
- Per-message rate display
- Connection status and latency

### Firmware
- Firmware page with Arduino / ESP32 sketch editor
- Arduino CLI integration for compile & flash
- Board selector (all installed Arduino platforms)
- Raw `.bin` flash via esptool

### Settings
- Theme, units (metric / imperial), map default location
- Connection defaults (baud rate, UDP port, system ID)

---

## Architecture

```
IndigenousGCS/
├── src/
│   ├── app/            Application bootstrap, AppSettings (QSettings wrapper)
│   ├── communication/  Connection (abstract), SerialConnection, UDPConnection,
│   │                   VirtualConnection, ConnectionManager
│   ├── mavlink/        MAVLinkParser, MAVLinkSender, MAVLinkManager
│   ├── msp/            MSPParser, MSPManager (INAV/Betaflight MSP protocol)
│   ├── vehicle/        Vehicle, VehicleState, Telemetry, FlightModeManager,
│   │                   CommandTracker, VehicleManager
│   ├── mission/        Waypoint, Mission, MissionManager, MissionSerializer
│   ├── parameters/     Parameter, ParameterManager
│   ├── calibration/    CalibrationManager
│   ├── safety/         SafetyManager, FailsafeManager
│   ├── logging/        FlightLogger (SQLite), LogReader
│   ├── firmware/       FirmwareManager (Arduino CLI / esptool)
│   ├── simulation/     Simulator (physics loop)
│   └── utils/          GeoUtils, Units, TimeUtils
├── qml/
│   ├── pages/          Dashboard, FlightData, MissionPlanner, Parameters,
│   │                   Calibration, VehicleSetup, InavConfigurator,
│   │                   Simulation, Logs, Diagnostics, Firmware, Settings
│   ├── components/     TopBar, SideBar, StatusBar, ConnectionPanel,
│   │                   ArtificialHorizon, FlightHud, AltitudeTape,
│   │                   Compass, BatteryIndicator, GPSIndicator,
│   │                   FlightModeSelector, NotificationPanel,
│   │                   TelemetryCard, VehicleStatus, IGButton, …
│   └── theme/          Colors, Theme
├── mavlink/            MAVLink C library headers (common + ardupilotmega dialects)
├── cmake/              Packaging.cmake, CMake helpers
├── resources/          App icon (.icns, .png)
├── tools/              package-macos.sh, build-windows.ps1
├── tests/              Unit tests (GTest) — geo, mavlink, mission,
│                       parameters, vehicle, msp
└── docs/               architecture.md, mavlink.md, esp32-integration.md,
                        mission-system.md, build-macos.md, build-windows.md
```

The UI layer (QML) communicates with the C++ backend exclusively through
Qt properties and signals. No QML file directly accesses hardware — all
hardware I/O goes through `ConnectionManager` → `MAVLinkManager` → domain
managers (`VehicleManager`, `MissionManager`, etc.).

---

## Requirements

| Dependency | Version |
|------------|---------|
| Qt | 6.5+ (Quick, QuickControls2, Location, Positioning, SerialPort, SQL, Network) |
| CMake | 3.21+ |
| C++ | 17 |
| Compiler | MSVC 2022 / Clang 14+ / GCC 11+ |

---

## Quick Start

```bash
# macOS (Homebrew)
brew install cmake qt@6
export CMAKE_PREFIX_PATH="$(brew --prefix qt@6)"

git clone <repo-url>
cd IndigenousGCS
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j8
open build/bin/IndigenousGCS.app
```

---

## Build — macOS

```bash
# Prerequisites
brew install cmake qt@6
export CMAKE_PREFIX_PATH="$(brew --prefix qt@6)"

# Build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j8

# Run
open build/bin/IndigenousGCS.app

# Tests
cd build && ctest --output-on-failure

# Create DMG
./tools/package-macos.sh
```

Full instructions: [`docs/build-macos.md`](docs/build-macos.md)

---

## Build — Windows

Requirements: Visual Studio 2022 (Desktop C++ workload), CMake 3.21+, and
Qt 6.5+ **MSVC 2022 64-bit**. NSIS is only needed for the installer.

```powershell
$QtDir = "C:\Qt\6.8.3\msvc2022_64"

# Visual Studio 2022 generator
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_PREFIX_PATH="$QtDir"
cmake --build build --config Release

# Or Ninja (from x64 Native Tools prompt)
cmake -S . -B build -G Ninja `
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$QtDir"
cmake --build build

# Deploy Qt and run
& "$QtDir\bin\windeployqt.exe" --release --qmldir qml build\bin\Release\IndigenousGCS.exe
.\build\bin\Release\IndigenousGCS.exe
```

### One-shot build, test, deploy and package

```powershell
# Full pipeline (build + tests + windeployqt + NSIS installer)
.\tools\build-windows.ps1 -QtDir $QtDir

# Build only, no installer
.\tools\build-windows.ps1 -QtDir $QtDir -SkipPackage
```

The script verifies that the Qt runtime really was deployed beside the
executable and warns if any core DLL is missing — the usual cause of a build
that runs on the developer's machine but not on a user's.

Full instructions, portable-folder deployment and a troubleshooting table:
[`docs/build-windows.md`](docs/build-windows.md)

---

## Running the Simulator

No hardware is required to try IndigenousGCS:

1. Launch the application
2. Navigate to the **Simulation** page
3. Click **START SIM**
4. Click **ARM** → **TAKEOFF**
5. Watch live telemetry on **Dashboard** and **Flight Data**

The simulator runs its own physics loop and generates realistic MAVLink
telemetry. It is labeled clearly as simulation and cannot trigger hardware
calibration, mission upload/download, or ARM on a real flight controller.

---

## Connecting to a Real ESP32 Flight Controller

1. Flash MAVLink firmware to the ESP32 (see [`docs/esp32-integration.md`](docs/esp32-integration.md))
2. Connect the ESP32 via USB serial
3. Open the **Diagnostics** page → select the serial port and baud rate → click **CONNECT**
4. The vehicle appears automatically when the first HEARTBEAT is received

Default baud rates: 57600, 115200, 230400, 460800, 921600  
Default UDP port: 14550

### Map tiles

The Mission Planner uses OpenStreetMap tiles — no API key is required. The map
starts centered on New Delhi. Upload, download, and **CLEAR FC** require an
active vehicle heartbeat.

### Calibration notes

Calibration commands are sent via MAVLink and rely on status text from the
connected firmware. Remove propellers before any calibration. ESC calibration
is hazardous — treat it with appropriate care.

### Firmware page notes

The Firmware page compiles and flashes Arduino/ESP32 sketches using Arduino
CLI. Install the target board platform via Arduino IDE's Boards Manager, then
click **LOAD BOARDS**. If the CLI is not found automatically, paste the path to
`arduino-cli` in the **ARDUINO CLI** field. For raw `.bin` flashing, install
Python 3 and `esptool` (`pip install esptool`).

---

## MAVLink Configuration

| Setting | Default |
|---------|---------|
| GCS System ID | 255 |
| GCS Component ID | 190 |
| UDP port | 14550 |
| Baud rates | 57600, 115200, 230400, 460800, 921600 |

---

## Contributing

1. Fork the repository and create a feature branch
2. Follow the existing code style (C++17, Qt conventions)
3. Add or update unit tests for new behaviour
4. Ensure `cmake --build build && ctest --test-dir build` passes
5. Open a pull request with a clear description

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for full guidelines.

---

## Documentation

| Document | Description |
|----------|-------------|
| [`docs/architecture.md`](docs/architecture.md) | Subsystem design and data-flow |
| [`docs/mavlink.md`](docs/mavlink.md) | MAVLink message handling details |
| [`docs/esp32-integration.md`](docs/esp32-integration.md) | ESP32 firmware setup |
| [`docs/mission-system.md`](docs/mission-system.md) | Mission planner internals |
| [`docs/build-macos.md`](docs/build-macos.md) | Full macOS build guide |
| [`docs/build-windows.md`](docs/build-windows.md) | Full Windows build guide |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No vehicle detected | Check baud rate; verify ESP32 sends HEARTBEAT |
| Parameters not loading | Ensure FC implements PARAM_REQUEST_LIST |
| Mission upload fails | Check FC implements MISSION_REQUEST_INT |
| Simulator not working | Click **START SIM** before **ARM** |
| Qt not found at build | Set `CMAKE_PREFIX_PATH` to Qt install dir |
| Missing DLLs on Windows | Run `windeployqt` against the built executable |
| App blocked by Gatekeeper | `xattr -cr build/bin/IndigenousGCS.app` |

---

## License

[MIT License](LICENSE) — Indigenous GCS Contributors
