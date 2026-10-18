import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import "pages"
import "theme"

ApplicationWindow {
    id: root
    visible: true
    minimumWidth:  1280
    minimumHeight: 720
    width:  1440
    height: 900
    title:  "Indigenous GCS"
    color:  Colors.bg0

    Component.onCompleted: {
        Colors.lightTheme = AppSettings.lightTheme
        splashTimer.start()
    }

    // Notification overlay for safety events
    Connections {
        target: SafetyManager
        function onSafetyEvent(level, message) {
            safetyBanner.show(level, message)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar    { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            SideBar {
                id: sidebar
                Layout.fillHeight: true
                onPageSelected: function(idx) {
                    if (idx >= 0 && idx < root.pages.length)
                        pageLoader.sourceComponent = root.pages[idx]
                }
            }

            // Main content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.bg0

                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/IndigenousGCS/resources/icons/app_icon.png"
                    width: Math.min(parent.width * 0.42, 360)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    opacity: Colors.lightTheme ? 0.10 : 0.09
                    smooth: true
                    // Behind the page loader (z 0 < 1) so it never paints over
                    // telemetry, and non-interactive so map panning still works.
                    z: 0
                    enabled: false
                    visible: status === Image.Ready
                }

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    z: 1
                    sourceComponent: dashboardComp
                }
            }
        }

        StatusBar { Layout.fillWidth: true }
    }

    Rectangle {
        id: splash
        anchors.fill: parent
        color: Colors.bg0
        visible: true
        z: 1000
        Image {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/IndigenousGCS/resources/icons/app_icon.png"
            width: 220; height: 220
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.verticalCenter; anchors.topMargin: 135; text: "INDIGENOUS GCS"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeLarge; font.bold: true; font.letterSpacing: 3 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.verticalCenter; anchors.topMargin: 170; text: "MADE WITH DEDICATION BY GARVIT PANT"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.letterSpacing: 1 }
        Timer { id: splashTimer; interval: 800; onTriggered: splash.visible = false }
    }

    // Safety banner
    Rectangle {
        id: safetyBanner
        anchors { top: parent.top; topMargin: 52; horizontalCenter: parent.horizontalCenter }
        width: bannerText.implicitWidth + 40; height: 36
        radius: Theme.radiusSmall
        color: Colors.critical
        visible: false
        z: 100

        Text {
            id: bannerText
            anchors.centerIn: parent
            color: Colors.textPrimary
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
            font.bold: true
        }

        Timer {
            id: bannerTimer
            interval: 5000
            onTriggered: safetyBanner.visible = false
        }

        function show(level, message) {
            const colors = [Colors.emergency, Colors.emergency, Colors.critical, Colors.critical,
                            Colors.warning, Colors.info, Colors.textSecondary, Colors.textDisabled]
            safetyBanner.color = colors[Math.min(level, 7)]
            bannerText.text = message
            safetyBanner.visible = true
            bannerTimer.restart()
        }

        TapHandler { onTapped: safetyBanner.visible = false }
    }

    // Page components. Order MUST match the SideBar entries below:
    // DASHBOARD, FLIGHT DATA, MISSION, PARAMETERS, INAV, CALIBRATION, VEHICLE,
    // FIRMWARE, SIMULATION, LOGS, DIAGNOSTICS, SETTINGS
    readonly property var pages: [
        dashboardComp, flightDataComp, missionComp, paramsComp, inavComp,
        calibComp, vehicleComp, firmwareComp, simComp, logsComp, diagComp, settingsComp
    ]

    Component { id: dashboardComp;  Dashboard   {} }
    Component { id: flightDataComp; FlightData  {} }
    Component { id: missionComp;    MissionPlanner {} }
    Component { id: paramsComp;     Parameters  {} }
    Component { id: inavComp;       InavConfigurator {} }
    Component { id: calibComp;      Calibration {} }
    Component { id: vehicleComp;    VehicleSetup {} }
    Component { id: logsComp;       Logs        {} }
    Component { id: firmwareComp;   Firmware    {} }
    Component { id: simComp;        Simulation  {} }
    Component { id: diagComp;       Diagnostics {} }
    Component { id: settingsComp;   Settings {} }
}
