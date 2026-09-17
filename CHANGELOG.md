# Changelog

## [1.1.0] — IAF / NCC Aerospace Theme

### Changed
- Rebranded UI to an **Indian Air Force / NCC aerospace** theme.
- Deep strategic-navy avionics palette (bg0–bg3) with **saffron (kesari)** primary accent.
- Tricolor (saffron / white / green) identity bar in the top bar.
- Aerospace indigo secondary accent and refined white/slate text hierarchy.
- Updated README with theme description.

## [1.0.0] — Initial Release

### Added
- MAVLink 2 serial and UDP communication
- Vehicle detection via heartbeat monitoring
- Real-time telemetry: attitude, GPS, battery, speed, flight mode
- Artificial horizon, compass, HUD components
- Mission planner with upload/download (full MAVLink protocol)
- Parameter manager with live read/write
- Calibration framework (accel, gyro, mag, level, RC, ESC)
- Safety monitoring with severity levels
- Flight logging to SQLite database
- Log viewer and session management
- Built-in flight simulator (no hardware required)
- Diagnostics page with MAVLink statistics
- Firmware info request
- Dark aerospace UI (Qt Quick / QML)
- Unit tests for geo, MAVLink, mission, parameters, vehicle
- Documentation: architecture, MAVLink, ESP32 integration, build guides
