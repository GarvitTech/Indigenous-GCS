# Contributing

## Code Style
- C++17, RAII, smart pointers, const correctness
- Qt signals/slots for cross-object communication
- No business logic in QML — only presentation
- All MAVLink commands must send real messages, no stubs

## Adding a New Page
1. Create `qml/pages/MyPage.qml`
2. Add component to `Main.qml` pages array
3. Add entry to `SideBar.qml` pages model
4. Add QML file to `CMakeLists.txt` QML_FILES list

## Adding a New MAVLink Message
1. Handle in `Vehicle::handleMessage()` switch
2. Add decode + state update method
3. Update `VehicleState` struct if new fields needed
4. Expose via `Telemetry` Q_PROPERTY if needed in QML
5. Add unit test in `tests/test_mavlink/`

## Running Tests
```bash
cd build && ctest --output-on-failure -V
```

## Commit Messages
```
feat: add barometer telemetry support
fix: correct GPS coordinate scaling
docs: update ESP32 integration guide
test: add mission serialization round-trip test
```
