cmake_minimum_required(VERSION 3.21)

project(IndigenousGCS
    VERSION 1.0.0
    DESCRIPTION "Cross-platform Ground Control Station for Indigenous ESP32 Flight Controllers"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Quick QuickControls2 Network SerialPort Sql Test
)

qt_standard_project_setup(REQUIRES 6.5)

set(MAVLINK_INCLUDE_DIR "${CMAKE_SOURCE_DIR}")

# ── All C++ sources ───────────────────────────────────────────────────────────
set(ALL_SOURCES
    src/main.cpp
    src/app/Application.cpp
    src/app/AppSettings.cpp
    src/communication/Connection.cpp
    src/communication/ConnectionManager.cpp
    src/communication/SerialConnection.cpp
    src/communication/UDPConnection.cpp
    src/mavlink/MAVLinkManager.cpp
    src/mavlink/MAVLinkParser.cpp
    src/mavlink/MAVLinkSender.cpp
    src/msp/MSPParser.cpp
    src/msp/MSPManager.cpp
    src/vehicle/Vehicle.cpp
    src/vehicle/VehicleState.cpp
    src/vehicle/Telemetry.cpp
    src/vehicle/FlightModeManager.cpp
    src/vehicle/VehicleManager.cpp
    src/mission/Mission.cpp
    src/mission/Waypoint.cpp
    src/mission/MissionManager.cpp
    src/mission/MissionSerializer.cpp
    src/parameters/Parameter.cpp
    src/parameters/ParameterManager.cpp
    src/calibration/CalibrationManager.cpp
    src/safety/SafetyManager.cpp
    src/safety/FailsafeManager.cpp
    src/logging/FlightLogger.cpp
    src/logging/LogReader.cpp
    src/firmware/FirmwareManager.cpp
    src/simulation/Simulator.cpp
    src/utils/Units.cpp
    src/utils/GeoUtils.cpp
    src/utils/TimeUtils.cpp
)

# ── Executable + QML module ───────────────────────────────────────────────────
qt_add_executable(IndigenousGCS ${ALL_SOURCES})

qt_add_qml_module(IndigenousGCS
    URI IndigenousGCS
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/pages/Dashboard.qml
        qml/pages/MissionPlanner.qml
        qml/pages/Parameters.qml
        qml/pages/InavConfigurator.qml
        qml/pages/Settings.qml
        qml/pages/Calibration.qml
        qml/pages/VehicleSetup.qml
        qml/pages/Logs.qml
        qml/pages/Firmware.qml
        qml/pages/Simulation.qml
        qml/pages/Diagnostics.qml
        qml/components/TopBar.qml
        qml/components/SideBar.qml
        qml/components/StatusBar.qml
        qml/components/TelemetryCard.qml
        qml/components/IGButton.qml
        qml/components/VehicleStatus.qml
        qml/components/FlightModeSelector.qml
        qml/components/AttitudeIndicator.qml
        qml/components/Compass.qml
        qml/components/ArtificialHorizon.qml
        qml/components/BatteryIndicator.qml
        qml/components/GPSIndicator.qml
        qml/components/ConnectionIndicator.qml
        qml/components/NotificationPanel.qml
        qml/theme/Theme.qml
        qml/theme/Colors.qml
    RESOURCES
        resources/icons/app_icon.png
        qml/theme/qmldir
)

target_include_directories(IndigenousGCS PRIVATE
    src
    ${CMAKE_SOURCE_DIR}
)

target_link_libraries(IndigenousGCS PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::SerialPort
    Qt6::Sql
)

# Install the executable and deploy the Qt/QML runtime beside it.  This is
# required for a portable Windows installer and keeps the macOS bundle usable
# outside the build tree.
include(GNUInstallDirs)
install(TARGETS IndigenousGCS
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if(QT_VERSION VERSION_GREATER_EQUAL "6.5")
    qt_generate_deploy_qml_app_script(
        TARGET IndigenousGCS
        OUTPUT_SCRIPT IndigenousGCS_deploy_script
        NO_TRANSLATIONS
    )
    install(SCRIPT ${IndigenousGCS_deploy_script})
endif()

# ── Tests ─────────────────────────────────────────────────────────────────────
enable_testing()
add_subdirectory(tests)

# ── Packaging ─────────────────────────────────────────────────────────────────
include(cmake/Packaging.cmake)
