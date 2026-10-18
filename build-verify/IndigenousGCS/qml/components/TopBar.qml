import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    height: Theme.topBarHeight
    color:  Colors.bg1

    // Bottom border line
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }

    // Tricolor left bar
    Column {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 4
        Rectangle { width: 4; height: parent.height / 3; color: "#ff9933" }
        Rectangle { width: 4; height: parent.height / 3; color: "#ffffff" }
        Rectangle { width: 4; height: parent.height / 3; color: "#138808" }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: Theme.spacingM }
        spacing: 0

        // Logo + Title
        Row {
            spacing: Theme.spacingS
            Rectangle {
                width: 28; height: 28
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                Text { anchors.centerIn: parent; text: "✈"; color: Colors.accent; font.pixelSize: 20 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Text { text: "INDIGENOUS GCS"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
                Text { text: "INDIAN AIR FORCE  ·  AEROSPACE COMMAND"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
            }
        }

        Item { width: Theme.spacingXL }

        // Sim badge
        Rectangle {
            visible: Simulator && Simulator.running
            color: Colors.warning; radius: Theme.radiusSmall
            width: simLbl.implicitWidth + 12; height: 20
            Text { id: simLbl; anchors.centerIn: parent; text: "⚠ SIM"; color: Colors.bg0; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
            SequentialAnimation on opacity {
                running: Simulator && Simulator.running; loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        Item { Layout.fillWidth: true }

        // Vehicle quick-status
        Row {
            spacing: Theme.spacingL
            visible: VehicleManager && VehicleManager.activeVehicle !== null

            property var tel: VehicleManager && VehicleManager.activeVehicle ? VehicleManager.activeVehicle.telemetry : null

            // Armed state
            Rectangle {
                width: armedTxt.implicitWidth + 16; height: 22; radius: Theme.radiusSmall
                color: (parent.tel && parent.tel.armed) ? "#3a0000" : "#003a00"
                border.color: (parent.tel && parent.tel.armed) ? Colors.critical : Colors.ok; border.width: 1
                Text { id: armedTxt; anchors.centerIn: parent
                    text: (parent.parent.tel && parent.parent.tel.armed) ? "● ARMED" : "● DISARMED"
                    color: (parent.parent.tel && parent.parent.tel.armed) ? Colors.critical : Colors.ok
                    font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
            }

            // Mode
            Rectangle {
                width: modeTxt.implicitWidth + 16; height: 22; radius: Theme.radiusSmall
                color: Colors.bg3; border.color: Colors.accentBlue; border.width: 1
                Text { id: modeTxt; anchors.centerIn: parent
                    text: parent.parent.tel ? parent.parent.tel.flightMode : "—"
                    color: Colors.accentBlue; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
            }

            // Battery
            Row {
                spacing: 4; anchors.verticalCenter: parent.verticalCenter
                Text { text: "BAT"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                Text {
                    property var t: parent.parent.parent.tel
                    text: t ? t.batteryRemaining + "%" : "—"
                    color: t && t.batteryRemaining < 20 ? Colors.critical : (t && t.batteryRemaining < 40 ? Colors.warning : Colors.ok)
                    font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                }
            }

            // GPS
            Row {
                spacing: 4; anchors.verticalCenter: parent.verticalCenter
                Text { text: "GPS"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                Text {
                    property var t: parent.parent.parent.tel
                    text: t ? t.gpsSatCount + " sat" : "—"
                    color: t && t.gpsSatCount >= 6 ? Colors.ok : Colors.warning
                    font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                }
            }
        }

        Item { width: Theme.spacingL }

        // Link status
        Row {
            spacing: 4; Layout.alignment: Qt.AlignVCenter
            Rectangle {
                width: 8; height: 8; radius: 4; anchors.verticalCenter: parent.verticalCenter
                color: MAVLinkManager && MAVLinkManager.hasPhysicalVehicle ? Colors.ok
                     : MAVLinkManager && MAVLinkManager.hasVehicle ? Colors.warning : Colors.textDisabled
                SequentialAnimation on opacity {
                    running: MAVLinkManager && MAVLinkManager.hasPhysicalVehicle; loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
            Text {
                text: MAVLinkManager && MAVLinkManager.hasPhysicalVehicle
                      ? MAVLinkManager.packetsPerSecond.toFixed(0) + " Hz"
                      : MAVLinkManager && MAVLinkManager.hasVehicle ? "SIMULATION ONLY" : "NO FC LINK"
                color: MAVLinkManager && MAVLinkManager.hasPhysicalVehicle ? Colors.ok
                     : MAVLinkManager && MAVLinkManager.hasVehicle ? Colors.warning : Colors.textDisabled
                font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
            }
        }

        Item { width: Theme.spacingM }

        IGButton {
            text: Colors.lightTheme ? "DARK" : "LIGHT"
            implicitWidth: 62
            implicitHeight: 24
            secondary: true
            onClicked: {
                Colors.lightTheme = !Colors.lightTheme
                AppSettings.lightTheme = Colors.lightTheme
            }
        }

        // Clock
        Text {
            id: clockTxt
            color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clockTxt.text = Qt.formatDateTime(new Date(), "hh:mm:ss UTC") }
            Component.onCompleted: text = Qt.formatDateTime(new Date(), "hh:mm:ss UTC")
        }
    }
}
