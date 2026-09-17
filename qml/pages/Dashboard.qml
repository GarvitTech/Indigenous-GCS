import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0
    property var tel: VehicleManager && VehicleManager.activeVehicle ? VehicleManager.activeVehicle.telemetry : null
    property var v:   VehicleManager ? VehicleManager.activeVehicle : null

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header bar
        Rectangle {
            Layout.fillWidth: true; height: 36
            color: Colors.bg1
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                Text { text: "DASHBOARD"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 3 }
                Item { Layout.fillWidth: true }
                VehicleStatus {}
                Item { width: Theme.spacingS }
                FlightModeSelector {}
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            // ── Column 1: Attitude + GPS ──────────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                spacing: 1

                // Artificial Horizon
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 280
                    color: Colors.bg1; border.color: Colors.border; border.width: 1
                    Column {
                        anchors { top: parent.top; left: parent.left; margins: Theme.spacingS }
                        Text { text: "ATTITUDE"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    }
                    ArtificialHorizon {
                        anchors.centerIn: parent
                        width: 240; height: 240
                        rollDeg:  tel ? tel.roll  : 0
                        pitchDeg: tel ? tel.pitch : 0
                    }
                }

                // Compass
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 200
                    color: Colors.bg1; border.color: Colors.border; border.width: 1
                    Column {
                        anchors { top: parent.top; left: parent.left; margins: Theme.spacingS }
                        Text { text: "HEADING"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    }
                    Compass {
                        anchors.centerIn: parent
                        width: 170; height: 170
                        heading: tel ? tel.heading : 0
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── Column 2: Telemetry cards ─────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                // Primary flight data
                Rectangle {
                    Layout.fillWidth: true; height: 36
                    color: Colors.bg2; border.color: Colors.border; border.width: 1
                    Text { anchors { left: parent.left; leftMargin: Theme.spacingM; verticalCenter: parent.verticalCenter }
                        text: "PRIMARY FLIGHT DATA"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 2 }
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 1; Layout.rightMargin: 1
                    spacing: 1

                    BigTelCard { label: "ALT REL";   value: tel ? tel.altitudeRel.toFixed(1) : "—"; unit: "m";   w: 130 }
                    BigTelCard { label: "ALT MSL";   value: tel ? tel.altitudeMSL.toFixed(1) : "—"; unit: "m";   w: 130 }
                    BigTelCard { label: "GND SPEED"; value: tel ? tel.groundSpeed.toFixed(1) : "—"; unit: "m/s"; w: 130 }
                    BigTelCard { label: "CLIMB";     value: tel ? tel.climbRate.toFixed(1)   : "—"; unit: "m/s"; w: 130; valueColor: tel && tel.climbRate > 0 ? Colors.ok : (tel && tel.climbRate < -0.5 ? Colors.warning : Colors.accent) }
                    BigTelCard { label: "ROLL";      value: tel ? tel.roll.toFixed(1)        : "—"; unit: "°";   w: 110 }
                    BigTelCard { label: "PITCH";     value: tel ? tel.pitch.toFixed(1)       : "—"; unit: "°";   w: 110 }
                    BigTelCard { label: "YAW";       value: tel ? tel.yaw.toFixed(1)         : "—"; unit: "°";   w: 110 }
                    BigTelCard { label: "HEADING";   value: tel ? tel.heading.toFixed(0)     : "—"; unit: "°";   w: 110 }
                }

                // GPS + Battery
                Rectangle {
                    Layout.fillWidth: true; height: 36
                    color: Colors.bg2; border.color: Colors.border; border.width: 1
                    Text { anchors { left: parent.left; leftMargin: Theme.spacingM; verticalCenter: parent.verticalCenter }
                        text: "GPS  ·  BATTERY  ·  POSITION"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 2 }
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 1; Layout.rightMargin: 1
                    spacing: 1

                    BigTelCard { label: "LATITUDE";   value: tel ? tel.latitude.toFixed(6)  : "—"; unit: "°";  w: 160 }
                    BigTelCard { label: "LONGITUDE";  value: tel ? tel.longitude.toFixed(6) : "—"; unit: "°";  w: 160 }
                    BigTelCard { label: "GPS FIX";    value: tel ? tel.gpsFixType.toString() : "—"; w: 100;
                        valueColor: tel && tel.gpsFixType >= 3 ? Colors.ok : Colors.warning }
                    BigTelCard { label: "SATELLITES"; value: tel ? tel.gpsSatCount.toString() : "—"; w: 100;
                        valueColor: tel && tel.gpsSatCount >= 6 ? Colors.ok : Colors.warning }
                    BigTelCard { label: "HDOP";       value: tel ? tel.hdop.toFixed(2) : "—"; w: 100 }
                    BigTelCard { label: "BATTERY";    value: tel ? tel.batteryRemaining + "%" : "—"; w: 110;
                        valueColor: tel && tel.batteryRemaining < 20 ? Colors.critical : (tel && tel.batteryRemaining < 40 ? Colors.warning : Colors.ok) }
                    BigTelCard { label: "VOLTAGE";    value: tel ? tel.batteryVoltage.toFixed(2) : "—"; unit: "V"; w: 110 }
                    BigTelCard { label: "CURRENT";    value: tel ? tel.batteryCurrent.toFixed(1) : "—"; unit: "A"; w: 110 }
                    BigTelCard { label: "CPU LOAD";   value: tel ? tel.cpuLoad + "‰" : "—"; w: 100 }
                }

                // Status messages
                Rectangle {
                    Layout.fillWidth: true; height: 36
                    color: Colors.bg2; border.color: Colors.border; border.width: 1
                    Text { anchors { left: parent.left; leftMargin: Theme.spacingM; verticalCenter: parent.verticalCenter }
                        text: "STATUS MESSAGES"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 2 }
                }

                NotificationPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    // Inline big telemetry card component
    component BigTelCard: Rectangle {
        property string label
        property string value:      "—"
        property string unit:       ""
        property color  valueColor: Colors.accent
        property int    w:          120
        width: w; height: 58
        color: Colors.bg2; border.color: Colors.border; border.width: 1

        Column {
            anchors { fill: parent; margins: 6 }
            spacing: 2
            Text { text: label; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
            Row {
                spacing: 3
                Text { text: value; color: valueColor; font.pixelSize: Theme.fontSizeLarge; font.family: Theme.fontFamily; font.bold: true }
                Text { text: unit; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; visible: unit !== ""; anchors.bottom: parent.bottom; bottomPadding: 3 }
            }
        }
    }
}
