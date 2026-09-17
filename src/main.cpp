#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QLoggingCategory>

#include "app/Application.h"
#include "app/AppSettings.h"
#include "communication/ConnectionManager.h"
#include "mavlink/MAVLinkManager.h"
#include "vehicle/VehicleManager.h"
#include "vehicle/Vehicle.h"
#include "vehicle/Telemetry.h"
#include "vehicle/FlightModeManager.h"
#include "mission/MissionManager.h"
#include "parameters/ParameterManager.h"
#include "calibration/CalibrationManager.h"
#include "safety/SafetyManager.h"
#include "logging/FlightLogger.h"
#include "logging/LogReader.h"
#include "firmware/FirmwareManager.h"
#include "msp/MSPManager.h"
#include "simulation/Simulator.h"

Q_LOGGING_CATEGORY(lcMain, "igcs.main")

int main(int argc, char *argv[])
{
    QGuiApplication::setApplicationName("IndigenousGCS");
    QGuiApplication::setOrganizationName("IndigenousGCS");
    QGuiApplication::setApplicationVersion("1.0.0");

    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");

    using namespace IndigenousGCS;

    // Register uncreatable types so QML can reference them
    qmlRegisterUncreatableType<Vehicle>("IndigenousGCS", 1, 0,
        "Vehicle", "Created by VehicleManager");
    qmlRegisterUncreatableType<Telemetry>("IndigenousGCS", 1, 0,
        "Telemetry", "Owned by Vehicle");

    // Initialise core application
    Application igcsApp;
    igcsApp.initialize();

    // Additional subsystems
    MissionManager     missionMgr(igcsApp.mavlinkManager());
    ParameterManager   paramMgr(igcsApp.mavlinkManager());
    CalibrationManager calibMgr(igcsApp.mavlinkManager());
    SafetyManager      safetyMgr;
    FirmwareManager    firmwareMgr(igcsApp.mavlinkManager());
    MSPManager         mspMgr(igcsApp.connectionManager());
    Simulator          simulator;
    LogReader          logReader;

    // Simulator bytes feed into MAVLink pipeline
    QObject::connect(&simulator,  &Simulator::bytesGenerated,
                     igcsApp.mavlinkManager(), &MAVLinkManager::processBytes);

    // Route MAVLink messages to mission and parameter managers
    QObject::connect(igcsApp.mavlinkManager(), &MAVLinkManager::messageReceived,
                     &missionMgr, &MissionManager::handleMessage);
    QObject::connect(igcsApp.mavlinkManager(), &MAVLinkManager::messageReceived,
                     &paramMgr,   &ParameterManager::handleMessage);

    // Wire vehicle status text to calibration manager when vehicle appears
    QObject::connect(igcsApp.mavlinkManager(), &MAVLinkManager::vehicleDetected,
                     [&](uint8_t, uint8_t) {
        VehicleManager *vm = igcsApp.vehicleManager();
        if (vm && vm->activeVehicle()) {
            QObject::connect(vm->activeVehicle(), &Vehicle::statusTextReceived,
                             &calibMgr, &CalibrationManager::onStatusText,
                             Qt::UniqueConnection);
        }
    });

    // QML engine
    QQmlApplicationEngine engine;
    QQmlContext *ctx = engine.rootContext();

    ctx->setContextProperty("AppSettings",        igcsApp.settings());
    ctx->setContextProperty("ConnectionManager",  igcsApp.connectionManager());
    ctx->setContextProperty("MAVLinkManager",     igcsApp.mavlinkManager());
    ctx->setContextProperty("VehicleManager",     igcsApp.vehicleManager());
    ctx->setContextProperty("MissionManager",     &missionMgr);
    ctx->setContextProperty("ParameterManager",   &paramMgr);
    ctx->setContextProperty("CalibrationManager", &calibMgr);
    ctx->setContextProperty("SafetyManager",      &safetyMgr);
    ctx->setContextProperty("FirmwareManager",    &firmwareMgr);
    ctx->setContextProperty("MSPManager",         &mspMgr);
    ctx->setContextProperty("Simulator",          &simulator);
    ctx->setContextProperty("FlightLogger",       igcsApp.flightLogger());
    ctx->setContextProperty("LogReader",          &logReader);

    const QUrl url(QStringLiteral("qrc:/qt/qml/IndigenousGCS/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    qCInfo(lcMain) << "Indigenous GCS v1.0.0 started";
    return app.exec();
}
