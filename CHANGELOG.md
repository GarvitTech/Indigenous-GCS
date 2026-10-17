# Changelog

All notable changes to IndigenousGCS are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

---

## [1.1.0] — IAF / NCC Aerospace Theme

### Changed
- Rebranded UI to an **Indian Air Force / NCC aerospace** theme
- Deep strategic-navy avionics palette (bg0–bg3) with **saffron (kesari)** primary accent
- Tricolor (saffron / white / green) identity bar in the top bar
- Aerospace indigo secondary accent and refined white/slate text hierarchy
- Updated README with theme description

---

## [1.0.0] — Initial Release

### Added

#### Communication
- MAVLink 2 serial communication (USB/UART) with configurable baud rate
- MAVLink 2 UDP communication with configurable port
- VirtualConnection for simulator / offline use
- ConnectionManager with auto-reconnect and connection-state tracking
- Heartbeat-based vehicle auto-detection

#### Flight Data & HUD
- Real-time telemetry: attitude (roll, pitch, yaw), GPS fix, battery
  voltage/current/percentage, airspeed, altitude, groundspeed, armed state, flight mode
- AnimatedHudCanvas with QML Canvas-based flight instruments
- Artificial horizon with aircraft symbol, roll/pitch animation, and sky/ground gradient
- Altitude tape with vertical speed indicator
- Compass rose with live heading
- FlightHud composite overlay combining all primary instruments
- Battery, GPS lock, and connection quality status indicators
- VehicleStatus summary widget

#### Mission Planner
- Interactive map using OpenStreetMap tiles (no API key required)
- Click-to-place and drag-to-move waypoints
- Mission upload to flight controller (MISSION_COUNT + MISSION_ITEM_INT protocol)
- Mission download from flight controller
- MISSION_CLEAR_ALL to wipe FC mission storage
- Local mission validation (altitude, coordinate sanity checks)
- Route line drawn on map, vehicle position marker, pan/zoom

#### Parameters
- Full parameter download via PARAM_REQUEST_LIST
- Live parameter write via PARAM_SET
- Search/filter by parameter name

#### Calibration
- Accelerometer calibration (MAV_CMD_PREFLIGHT_CALIBRATION)
- Gyroscope calibration
- Magnetometer / compass calibration
- Level horizon calibration
- RC channel calibration
- ESC calibration
- STATUSTEXT progress feedback

#### INAV / MSP Support
- MSP binary protocol parser and framer
- MSPManager for INAV/Betaflight targets
- InavConfigurator page: board info, sensor status, PID profile read/write/save

#### Safety & Failsafe
- SafetyManager — real-time checks with severity levels (info/warning/error/critical)
- FailsafeManager — configurable threshold monitoring
- NotificationPanel — in-app alert display with dismiss and history

#### Simulation
- Built-in physics-based flight simulator (no hardware required)
- Simulated attitude, GPS, battery, speed, and heartbeat
- Simulator controls: START / STOP, ARM, TAKEOFF, LAND
- Clearly labeled as simulation; isolated from hardware actions

#### Logging
- FlightLogger — records telemetry sessions to SQLite
- LogReader — session browser, entry viewer, export

#### Diagnostics
- MAVLink inspector: per-message counters, rates, last-seen timestamps
- Connection statistics (bytes in/out, packet rate, latency)
- Raw STATUSTEXT log

#### Firmware (ESP32 / Arduino)
- FirmwareManager — Arduino CLI integration for compile & flash
- Sketch editor with syntax highlighting
- Board selector (reads all installed Arduino platforms)
- Raw `.bin` upload via esptool

#### Settings
- AppSettings (QSettings-backed)
- Theme, unit system (metric/imperial), default map location
- Connection defaults: baud rate, UDP port, GCS system/component IDs

#### Build & Packaging
- CMake 3.21+ build system with platform-specific Packaging.cmake
- macOS: .app bundle with Info.plist metadata, .icns icon
- macOS: CPack DragNDrop generator producing `IndigenousGCS-1.0.0-macOS.dmg`
- Windows: CPack NSIS generator producing `IndigenousGCS-1.0.0-Windows.exe`
- `tools/package-macos.sh` — one-command DMG builder with macdeployqt
- `tools/build-windows.ps1` — one-command Windows build + NSIS installer
- GitHub Actions CI workflow for Windows builds

#### Testing
- GTest unit test suite
- test_geo: GeoUtils (Haversine distance, bearing, coordinate conversion)
- test_mavlink: MAVLink message parsing and encoding
- test_mission: Mission serialization, waypoint operations
- test_parameters: Parameter read/write round-trips
- test_vehicle: Vehicle state transitions and telemetry parsing
- test_msp: MSP protocol framing and parsing

#### Documentation
- `docs/architecture.md` — subsystem design and data-flow
- `docs/mavlink.md` — MAVLink message handling reference
- `docs/esp32-integration.md` — ESP32 firmware setup guide
- `docs/mission-system.md` — mission planner internals
- `docs/build-macos.md` — comprehensive macOS build guide (Homebrew + Qt Installer, DMG)
- `docs/build-windows.md` — comprehensive Windows build guide (VS + Ninja, NSIS)
