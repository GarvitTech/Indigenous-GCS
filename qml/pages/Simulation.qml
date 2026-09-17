import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0
    property var tel: VehicleManager && VehicleManager.activeVehicle ? VehicleManager.activeVehicle.telemetry : null

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        RowLayout {
            spacing: Theme.spacingS
            Text { text: "SIMULATION"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
            Rectangle {
                visible: Simulator.running; color: Colors.warning; radius: Theme.radiusSmall
                width: badge.implicitWidth + 16; height: 24
                Text { id: badge; anchors.centerIn: parent; text: "⚠  SIMULATION ACTIVE"; color: Colors.bg0; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
            }
        }

        Rectangle {
            Layout.preferredWidth: 520; height: 200
            color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1
            ColumnLayout {
                anchors { fill: parent; margins: Theme.spacingM }
                spacing: Theme.spacingM
                Text { text: "SIMULATOR CONTROLS"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                Text { text: "State: " + Simulator.simState; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily; font.bold: true }
                RowLayout {
                    spacing: Theme.spacingS
                    IGButton { text: Simulator.running ? "STOP SIM" : "START SIM"; implicitWidth: 110; danger: Simulator.running
                        onClicked: Simulator.running ? Simulator.stop() : Simulator.start() }
                    IGButton { text: "ARM";     implicitWidth: 70;  enabled: Simulator.running; onClicked: Simulator.arm() }
                    IGButton { text: "DISARM";  implicitWidth: 80;  enabled: Simulator.running; danger: true; onClicked: Simulator.disarm() }
                    IGButton { text: "TAKEOFF"; implicitWidth: 90;  enabled: Simulator.running; onClicked: Simulator.takeoff(10.0) }
                    IGButton { text: "LAND";    implicitWidth: 70;  enabled: Simulator.running; onClicked: Simulator.land() }
                }
                Text {
                    text: "The simulator generates real MAVLink packets fed into the GCS pipeline.\nNo real motors or hardware are involved."
                    color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
            }
        }

        Flow {
            Layout.fillWidth: true; spacing: Theme.spacingS; visible: Simulator.running
            TelemetryCard { label: "ALT REL";  value: tel ? tel.altitudeRel.toFixed(1) : "—"; unit: "m" }
            TelemetryCard { label: "GND SPD";  value: tel ? tel.groundSpeed.toFixed(1) : "—"; unit: "m/s" }
            TelemetryCard { label: "ROLL";     value: tel ? tel.roll.toFixed(1)        : "—"; unit: "°" }
            TelemetryCard { label: "PITCH";    value: tel ? tel.pitch.toFixed(1)       : "—"; unit: "°" }
            TelemetryCard { label: "HEADING";  value: tel ? tel.heading.toFixed(0)     : "—"; unit: "°" }
            TelemetryCard { label: "BATTERY";  value: tel ? tel.batteryRemaining + "%" : "—" }
            TelemetryCard { label: "MODE";     value: tel ? tel.flightMode             : "—" }
        }

        Item { Layout.fillHeight: true }
    }
}
