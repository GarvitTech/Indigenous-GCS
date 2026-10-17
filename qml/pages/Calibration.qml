import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0
    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null
    property int selectedTarget: 0
    readonly property var calibrationOptions: [
        {
            label: "Accelerometer", icon: "⊕", target: 0,
            summary: "Calibrates the accelerometer reference used for attitude and level estimation.",
            instructions: ["Remove the propellers and secure the aircraft.", "Place the frame on each prompted face, holding it still.", "Keep the controller connected until the flight controller reports completion."]
        },
        {
            label: "Gyroscope", icon: "↻", target: 1,
            summary: "Sets the gyro zero-rate reference. Movement during this step can degrade the result.",
            instructions: ["Remove propellers and place the aircraft on a stable, level surface.", "Do not touch or move the frame while calibration runs.", "Wait for the controller status message before moving the aircraft."]
        },
        {
            label: "Magnetometer", icon: "◎", target: 2,
            summary: "Calibrates the magnetic heading sensors. Nearby metal and current-carrying wires can affect the result.",
            instructions: ["Move to an open area away from vehicles, reinforced concrete, and magnets.", "Rotate the aircraft slowly through different orientations.", "Complete only when the controller confirms the calibration."]
        },
        {
            label: "Level", icon: "═", target: 3,
            summary: "Records the level reference with the aircraft resting in its normal flight attitude.",
            instructions: ["Remove propellers and place the aircraft on a truly level surface.", "Align the frame in its normal forward-facing orientation.", "Keep it still until the flight controller reports completion."]
        },
        {
            label: "Radio / RC", icon: "⊞", target: 4,
            summary: "Requests RC endpoint calibration where supported by the connected flight-controller firmware.",
            instructions: ["Remove propellers and ensure the transmitter is bound.", "Move each stick and switch through its full range as directed by the controller.", "Check channel direction and failsafe settings before flight."]
        },
        {
            label: "ESC", icon: "⚡", target: 5,
            summary: "Requests ESC calibration where supported. This can spin motors and must be treated as hazardous.",
            instructions: ["Remove every propeller and keep the aircraft restrained.", "Follow the exact procedure for your ESC and flight-controller firmware.", "Do not proceed unless the area is clear and the battery can be disconnected immediately."]
        }
    ]
    readonly property var selectedCalibration: calibrationOptions[selectedTarget]
    readonly property bool isCalibrating: CalibrationManager.status === 1

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "FLIGHT CONTROLLER SETUP  /  CALIBRATION"
                color: Colors.accent
                font.pixelSize: Theme.fontSizeMedium
                font.family: Theme.fontFamily
                font.bold: true
                font.letterSpacing: 1.5
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 3
                color: root.vehicle && !root.vehicle.simulated ? Colors.ok : Colors.warning
                implicitWidth: connectionLabel.implicitWidth + Theme.spacingM
                implicitHeight: 28
                Text {
                    id: connectionLabel
                    anchors.centerIn: parent
                    text: root.vehicle ? (root.vehicle.simulated ? "SIMULATOR — NO CONTROLLER" : "CONTROLLER CONNECTED")
                                       : "NO CONTROLLER"
                    color: Colors.bg0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeTiny
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(58, calibrationMessage.implicitHeight + Theme.spacingM * 2)
            color: Colors.bg2
            radius: Theme.radiusSmall
            border.color: Colors.border
            RowLayout {
                anchors { fill: parent; margins: Theme.spacingM }
                spacing: Theme.spacingM
                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.fillHeight: true
                    radius: 3
                    color: root.isCalibrating ? Colors.warning
                         : CalibrationManager.status === 2 ? Colors.ok
                         : CalibrationManager.status === 3 ? Colors.critical : Colors.accent
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: root.isCalibrating ? "CALIBRATION IN PROGRESS"
                              : CalibrationManager.status === 2 ? "CALIBRATION COMPLETE"
                              : CalibrationManager.status === 3 ? "CALIBRATION FAILED"
                              : "READY"
                        color: Colors.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        font.bold: true
                        font.letterSpacing: 1
                    }
                    Text {
                        id: calibrationMessage
                        Layout.fillWidth: true
                        text: CalibrationManager.message || "Select a procedure and review its safety steps before starting."
                        color: Colors.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 5
                        radius: 3
                        color: Colors.bg3
                        visible: root.isCalibrating
                        Rectangle {
                            width: parent.width * CalibrationManager.progress / 100
                            height: parent.height
                            radius: parent.radius
                            color: Colors.accent
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                    }
                }
                Text {
                    visible: root.isCalibrating
                    text: CalibrationManager.progress + "%"
                    color: Colors.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.bold: true
                }
                IGButton {
                    visible: root.isCalibrating
                    text: "CANCEL"
                    danger: true
                    implicitWidth: 90
                    onClicked: CalibrationManager.cancelCalibration()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingM

            Rectangle {
                Layout.preferredWidth: 250
                Layout.fillHeight: true
                color: Colors.bg1
                radius: Theme.radiusSmall
                border.color: Colors.border
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        Layout.margins: Theme.spacingM
                        text: "PROCEDURES"
                        color: Colors.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        font.bold: true
                        font.letterSpacing: 1
                    }
                    Repeater {
                        model: root.calibrationOptions
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            color: root.selectedTarget === index ? Colors.accentGlow : "transparent"
                            Rectangle {
                                width: 3
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                color: root.selectedTarget === index ? Colors.accent : "transparent"
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingS }
                                Text { text: modelData.icon; color: root.selectedTarget === index ? Colors.accent : Colors.textSecondary; font.pixelSize: Theme.fontSizeMedium; Layout.preferredWidth: 28 }
                                Text { text: modelData.label; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true }
                                Text { text: "›"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeMedium }
                            }
                            TapHandler { onTapped: root.selectedTarget = index }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.bg1
                radius: Theme.radiusSmall
                border.color: Colors.border
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingL }
                    spacing: Theme.spacingM

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.selectedCalibration.icon; color: Colors.accent; font.pixelSize: 30 }
                        Text {
                            text: root.selectedCalibration.label.toUpperCase()
                            color: Colors.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.selectedCalibration.summary
                        color: Colors.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeNormal
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colors.border
                    }

                    Text {
                        text: "BEFORE YOU BEGIN"
                        color: Colors.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        font.bold: true
                        font.letterSpacing: 1
                    }
                    Repeater {
                        model: root.selectedCalibration.instructions
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingM
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 12
                                color: Colors.bg3
                                Text {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    color: Colors.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeTiny
                                    font.bold: true
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: Colors.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: safetyText.implicitHeight + Theme.spacingM
                        color: Colors.bg2
                        radius: Theme.radiusSmall
                        border.color: Colors.warning
                        Text {
                            id: safetyText
                            anchors { fill: parent; margins: Theme.spacingS }
                            text: "SAFETY: Remove propellers before calibration. ESC procedures are hazardous. Availability and completion messages depend on the connected firmware; this app reports controller status and does not simulate calibration results."
                            color: Colors.warning
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeTiny
                            wrapMode: Text.WordWrap
                        }
                    }

                    Item { Layout.fillHeight: true }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: root.vehicle && root.vehicle.simulated
                                  ? "Simulation is not a flight controller; connect real hardware to calibrate."
                                  : root.vehicle ? "Target: system " + root.vehicle.sysId : "Connect a flight controller to start."
                            color: Colors.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        IGButton {
                            text: "START " + root.selectedCalibration.label.toUpperCase()
                            implicitWidth: 210
                            enabled: root.vehicle !== null && !root.vehicle.simulated && !root.isCalibrating
                            active: true
                            onClicked: {
                                if (root.vehicle)
                                    CalibrationManager.startCalibration(root.vehicle.sysId,
                                                                         root.vehicle.compId,
                                                                         root.selectedCalibration.target)
                            }
                        }
                    }
                }
            }
        }
    }
}
