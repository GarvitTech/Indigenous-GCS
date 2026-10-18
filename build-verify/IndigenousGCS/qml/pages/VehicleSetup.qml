import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0
    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null
    property var tel: vehicle ? vehicle.telemetry : null

    ScrollView {
        anchors.fill: parent; contentWidth: availableWidth

        ColumnLayout {
            width: parent.width; spacing: Theme.spacingM
            anchors.margins: Theme.spacingL

            Text { text: "VEHICLE SETUP"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2; Layout.topMargin: Theme.spacingL; Layout.leftMargin: Theme.spacingL }

            // Vehicle info card
            Rectangle {
                Layout.leftMargin: Theme.spacingL; Layout.preferredWidth: 400; height: 160
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingM }
                    spacing: 8
                    Text { text: "VEHICLE INFORMATION"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }

                    Repeater {
                        model: [
                            ["System ID",    vehicle ? vehicle.sysId.toString() : "—"],
                            ["Component ID", vehicle ? vehicle.compId.toString() : "—"],
                            ["Flight Mode",  tel ? tel.flightMode : "—"],
                            ["Armed",        tel ? (tel.armed ? "YES" : "NO") : "—"]
                        ]
                        delegate: RowLayout {
                            spacing: Theme.spacingM
                            Text { text: modelData[0] + ":"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 120 }
                            Text { text: modelData[1]; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
                        }
                    }
                }
            }

            // Sensor health
            Rectangle {
                Layout.leftMargin: Theme.spacingL; Layout.preferredWidth: 400; height: 140
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingM }
                    spacing: 8
                    Text { text: "SENSOR HEALTH"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }

                    Repeater {
                        model: ["Gyroscope","Accelerometer","Magnetometer","GPS","Barometer"]
                        delegate: RowLayout {
                            spacing: Theme.spacingS
                            Rectangle { width: 8; height: 8; radius: 4; color: Colors.ok }
                            Text { text: modelData; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                        }
                    }
                }
            }

            // Firmware info
            Rectangle {
                Layout.leftMargin: Theme.spacingL; Layout.preferredWidth: 400; height: 100
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingM }
                    spacing: 8
                    Text { text: "FIRMWARE"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    Text { text: "Version: " + (FirmwareManager.currentVersion || "Unknown"); color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    IGButton {
                        text: "REQUEST INFO"; implicitWidth: 140; implicitHeight: 28; enabled: vehicle !== null
                        onClicked: { if (vehicle) FirmwareManager.requestFirmwareInfo(vehicle.sysId, vehicle.compId) }
                    }
                }
            }

            Item { height: Theme.spacingL }
        }
    }
}
