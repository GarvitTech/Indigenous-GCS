import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0

    property var tel: VehicleManager && VehicleManager.activeVehicle
                      ? VehicleManager.activeVehicle.telemetry : null

    RowLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        // Left: HUD + Compass
        ColumnLayout {
            spacing: Theme.spacingM
            Layout.preferredWidth: 280

            Text { text: "FLIGHT DATA"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }

            ArtificialHorizon {
                width: 260; height: 260
                rollDeg:  tel ? tel.roll  : 0
                pitchDeg: tel ? tel.pitch : 0
            }

            Compass {
                width: 160; height: 160
                anchors.horizontalCenter: parent.horizontalCenter
                heading: tel ? tel.heading : 0
            }

            AttitudeIndicator {
                width: 260; height: 70
                rollDeg: tel ? tel.roll : 0
            }

            Item { Layout.fillHeight: true }
        }

        // Right: telemetry cards + messages
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingM

            RowLayout {
                spacing: Theme.spacingS
                VehicleStatus {}
                FlightModeSelector {}
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacingS
                TelemetryCard { label: "ALT REL";    value: tel ? tel.altitudeRel.toFixed(1) : "—"; unit: "m" }
                TelemetryCard { label: "ALT MSL";    value: tel ? tel.altitudeMSL.toFixed(1) : "—"; unit: "m" }
                TelemetryCard { label: "GND SPD";    value: tel ? tel.groundSpeed.toFixed(1) : "—"; unit: "m/s" }
                TelemetryCard { label: "AIR SPD";    value: tel ? tel.airSpeed.toFixed(1)    : "—"; unit: "m/s" }
                TelemetryCard { label: "CLIMB";      value: tel ? tel.climbRate.toFixed(1)   : "—"; unit: "m/s" }
                TelemetryCard { label: "HEADING";    value: tel ? tel.heading.toFixed(0)     : "—"; unit: "°" }
                TelemetryCard { label: "ROLL";       value: tel ? tel.roll.toFixed(1)        : "—"; unit: "°" }
                TelemetryCard { label: "PITCH";      value: tel ? tel.pitch.toFixed(1)       : "—"; unit: "°" }
                TelemetryCard { label: "LAT";        value: tel ? tel.latitude.toFixed(6)    : "—" }
                TelemetryCard { label: "LON";        value: tel ? tel.longitude.toFixed(6)   : "—" }
                TelemetryCard { label: "BATTERY";    value: tel ? tel.batteryRemaining + "%" : "—"; valueColor: tel && tel.batteryRemaining < 20 ? Colors.critical : Colors.ok }
                TelemetryCard { label: "VOLTAGE";    value: tel ? tel.batteryVoltage.toFixed(2) : "—"; unit: "V" }
                TelemetryCard { label: "GPS FIX";    value: tel ? tel.gpsFixType.toString()  : "—" }
                TelemetryCard { label: "SATS";       value: tel ? tel.gpsSatCount.toString() : "—" }
            }

            NotificationPanel { Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }
}
