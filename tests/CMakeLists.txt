cmake_minimum_required(VERSION 3.21)

find_package(Qt6 REQUIRED COMPONENTS Test Core Sql)

set(MAVLINK_INCLUDE_DIR "${CMAKE_SOURCE_DIR}")
set(SRC "${CMAKE_SOURCE_DIR}/src")

# ── test_geo ──────────────────────────────────────────────────────────────────
qt_add_executable(test_geo
    test_geo/test_geo.cpp
    ${SRC}/utils/GeoUtils.cpp
)
target_include_directories(test_geo PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_geo PRIVATE Qt6::Test Qt6::Core)
add_test(NAME test_geo COMMAND test_geo)

# ── test_mavlink ──────────────────────────────────────────────────────────────
qt_add_executable(test_mavlink
    test_mavlink/test_mavlink.cpp
)
target_include_directories(test_mavlink PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_mavlink PRIVATE Qt6::Test Qt6::Core)
add_test(NAME test_mavlink COMMAND test_mavlink)

# ── test_msp ──────────────────────────────────────────────────────────────────
qt_add_executable(test_msp
    test_msp/test_msp.cpp
    ${SRC}/msp/MSPParser.cpp
)
target_include_directories(test_msp PRIVATE ${SRC})
target_link_libraries(test_msp PRIVATE Qt6::Test Qt6::Core)
add_test(NAME test_msp COMMAND test_msp)

# ── test_mission ──────────────────────────────────────────────────────────────
qt_add_executable(test_mission
    test_mission/test_mission.cpp
    ${SRC}/mission/Mission.cpp
    ${SRC}/mission/Waypoint.cpp
    ${SRC}/mission/MissionSerializer.cpp
)
target_include_directories(test_mission PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_mission PRIVATE Qt6::Test Qt6::Core)
add_test(NAME test_mission COMMAND test_mission)

# ── test_parameters ───────────────────────────────────────────────────────────
qt_add_executable(test_parameters
    test_parameters/test_parameters.cpp
    ${SRC}/parameters/Parameter.cpp
)
target_include_directories(test_parameters PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_parameters PRIVATE Qt6::Test Qt6::Core)
add_test(NAME test_parameters COMMAND test_parameters)

# ── test_vehicle ──────────────────────────────────────────────────────────────
qt_add_executable(test_vehicle
    test_vehicle/test_vehicle.cpp
    ${SRC}/vehicle/FlightModeManager.cpp
    ${SRC}/vehicle/VehicleState.cpp
)
target_include_directories(test_vehicle PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_vehicle PRIVATE Qt6::Test Qt6::Core)
add_test(NAME test_vehicle COMMAND test_vehicle)

# ── test_guide ────────────────────────────────────────────────────────────────
# The guide is a Qt resource owned by the main target, so this test links the
# resource in directly rather than depending on the application binary.
qt_add_executable(test_guide
    test_guide/test_guide.cpp
)
target_include_directories(test_guide PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_guide PRIVATE Qt6::Test Qt6::Core)

qt_add_resources(test_guide guide_resources
    PREFIX "/docs"
    BASE "${CMAKE_SOURCE_DIR}/resources/docs"
    FILES ${CMAKE_SOURCE_DIR}/resources/docs/guide.html
)

add_test(NAME test_guide COMMAND test_guide)

# ── test_logging ──────────────────────────────────────────────────────────────
# Exercises the real FlightLogger + LogReader against a real SQLite database.
# This is the test that catches the writer/reader path divergence that made
# recordings invisible in the Logs page.
qt_add_executable(test_logging
    test_logging/test_logging.cpp
    ${SRC}/logging/FlightLogger.cpp
    ${SRC}/logging/LogReader.cpp
    ${SRC}/logging/LogPaths.cpp
)
target_include_directories(test_logging PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_logging PRIVATE Qt6::Test Qt6::Core Qt6::Sql)
add_test(NAME test_logging COMMAND test_logging)

# ── test_logging_integration ────────────────────────────────────────────────
# Behavioural end-to-end check of the record -> stop -> list -> read -> export
# sequence that the Logs page performs.
qt_add_executable(test_logging_integration
    test_logging/test_logging_integration.cpp
    ${SRC}/logging/FlightLogger.cpp
    ${SRC}/logging/LogReader.cpp
    ${SRC}/logging/LogPaths.cpp
)
target_include_directories(test_logging_integration PRIVATE ${SRC} ${MAVLINK_INCLUDE_DIR})
target_link_libraries(test_logging_integration PRIVATE Qt6::Test Qt6::Core Qt6::Sql)
add_test(NAME test_logging_integration COMMAND test_logging_integration)
