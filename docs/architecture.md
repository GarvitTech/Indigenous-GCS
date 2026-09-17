# Indigenous GCS — Architecture

## Threading Model

```
Main Thread (Qt Event Loop)
├── QML UI Engine
├── Application (owns all subsystems)
└── Signal/slot dispatch

Communication (runs on main thread via Qt async I/O)
├── SerialConnection  — QSerialPort (async readyRead)
└── UDPConnection     — QUdpSocket  (async readyRead)

MAVLink Pipeline (main thread, non-blocking)
├── MAVLinkParser  — byte-by-byte state machine
├── MAVLinkManager — dispatch, heartbeat monitoring
└── MAVLinkSender  — encode and emit bytes

Vehicle Layer (main thread)
├── VehicleManager — creates/removes Vehicle instances
├── Vehicle        — decodes messages, updates state
└── Telemetry      — QObject with Q_PROPERTY for QML binding

Background Workers
├── FlightLogger   — batched SQLite writes (flush every 10 records)
└── Simulator      — QTimer-driven tick at 100ms
```

## Data Flow

```
Serial/UDP bytes
    → ConnectionManager::bytesReceived
    → MAVLinkManager::processBytes
    → MAVLinkParser::parseBytes
    → MAVLinkParser::messageReceived
    → MAVLinkManager::onMessageReceived
    → MAVLinkManager::messageReceived (broadcast)
    → VehicleManager::onMessageReceived
    → Vehicle::handleMessage
    → VehicleState updated
    → Telemetry::update
    → QML properties notify
    → UI redraws
```

## QML/C++ Boundary

C++ exposes to QML via `QQmlContext::setContextProperty`:
- `AppSettings`       — persistent settings
- `ConnectionManager` — connect/disconnect
- `MAVLinkManager`    — stats
- `VehicleManager`    — active vehicle
- `MissionManager`    — upload/download
- `ParameterManager`  — param read/write
- `CalibrationManager`— calibration commands
- `SafetyManager`     — safety events
- `FirmwareManager`   — firmware info
- `Simulator`         — simulation control
- `FlightLogger`      — log start/stop
- `LogReader`         — log playback

QML never directly accesses MAVLink or serial — all commands go through C++ methods.

## Safety Design

- ARM requires explicit user confirmation dialog
- DISARM requires explicit user confirmation
- Safety events are displayed as non-dismissable banners
- Heartbeat timeout triggers LOST state immediately
- Simulator is clearly labelled — cannot accidentally arm real vehicle
- No automatic arming, launching, or mission execution
