import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0
    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        Text { text: "CALIBRATION"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }

        // Status
        Rectangle {
            Layout.fillWidth: true; height: 60
            color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1
            ColumnLayout {
                anchors { fill: parent; margins: Theme.spacingM }
                spacing: 4
                Text {
                    text: CalibrationManager.message || "Select a calibration to begin."
                    color: {
                        switch(CalibrationManager.status) {
                        case 1: return Colors.warning
                        case 2: return Colors.ok
                        case 3: return Colors.critical
                        case 4: return Colors.textDisabled
                        default: return Colors.textSecondary
                        }
                    }
                    font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                Rectangle {
                    Layout.fillWidth: true; height: 6; color: Colors.bg3; radius: 3
                    visible: CalibrationManager.status === 1
                    Rectangle {
                        width: parent.width * CalibrationManager.progress / 100
                        height: parent.height; radius: parent.radius; color: Colors.accent
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }
            }
        }

        // Calibration buttons
        GridLayout {
            columns: 3; columnSpacing: Theme.spacingM; rowSpacing: Theme.spacingM

            Repeater {
                model: [
                    { label: "Accelerometer", icon: "⊕", target: 0 },
                    { label: "Gyroscope",     icon: "↻", target: 1 },
                    { label: "Magnetometer",  icon: "◎", target: 2 },
                    { label: "Level",         icon: "═", target: 3 },
                    { label: "Radio / RC",    icon: "⊞", target: 4 },
                    { label: "ESC",           icon: "⚡", target: 5 }
                ]

                delegate: Rectangle {
                    width: 200; height: 90
                    color: Colors.bg2; radius: Theme.radiusMedium
                    border.color: Colors.border; border.width: 1

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spacingM }
                        spacing: Theme.spacingS
                        Text { text: modelData.icon + "  " + modelData.label; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily; font.bold: true }
                        IGButton {
                            text: "START"; implicitWidth: 100; implicitHeight: 28
                            enabled: vehicle !== null && CalibrationManager.status !== 1
                            onClicked: {
                                if (vehicle)
                                    CalibrationManager.startCalibration(vehicle.sysId, vehicle.compId, modelData.target)
                            }
                        }
                    }
                }
            }
        }

        IGButton {
            text: "CANCEL CALIBRATION"; danger: true; implicitWidth: 200
            visible: CalibrationManager.status === 1
            onClicked: CalibrationManager.cancelCalibration()
        }

        Item { Layout.fillHeight: true }
    }
}
