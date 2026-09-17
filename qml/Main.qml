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
                    opacity: Colors.lightTheme ? 0.18 : 0.16
                    smooth: true
                    z: 2
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
        Timer { id: splashTimer; interval: 5000; onTriggered: splash.visible = false }
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

    // Page components
    readonly property var pages: [
        dashboardComp, missionComp, paramsComp, inavComp,
        calibComp, vehicleComp, logsComp, firmwareComp, simComp, diagComp, settingsComp
    ]

    Component { id: dashboardComp;  Dashboard   {} }
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
