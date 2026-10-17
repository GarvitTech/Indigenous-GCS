import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property var tel: VehicleManager && VehicleManager.activeVehicle
                      ? VehicleManager.activeVehicle.telemetry : null

    // ── Animated warning border when running ──────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 0
        border.width: Simulator && Simulator.running ? 3 : 0
        border.color: Colors.warning
        z: 5
        opacity: 0.8

        SequentialAnimation on border.color {
            running: Simulator && Simulator.running
            loops: Animation.Infinite
            ColorAnimation { to: Colors.critical; duration: 800 }
            ColorAnimation { to: Colors.warning;  duration: 800 }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        // ── TITLE ─────────────────────────────────────────────────────────
        RowLayout {
            spacing: Theme.spacingM
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 4
                Text {
                    text: "SIMULATION MODE"
                    color: Simulator && Simulator.running ? Colors.warning : Colors.accent
                    font.pixelSize: Theme.fontSizeHuge
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.letterSpacing: 3
                }
                Text {
                    text: "THIS IS A SOFTWARE SIMULATION — NO REAL AIRCRAFT"
                    color: Colors.critical
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.letterSpacing: 1
                }
            }

            Item { Layout.fillWidth: true }

            // Running badge
            Rectangle {
                visible: Simulator && Simulator.running
                color: Colors.critical
                radius: Theme.radiusSmall
                width: runBadge.implicitWidth + 20
                height: 30
                SequentialAnimation on color {
                    running: Simulator && Simulator.running
                    loops: Animation.Infinite
                    ColorAnimation { to: "#990000"; duration: 500 }
                    ColorAnimation { to: Colors.critical; duration: 500 }
                }
                Text {
                    id: runBadge
                    anchors.centerIn: parent
                    text: "⚠  SIM ACTIVE"
                    color: "#ffffff"
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.bold: true
                }
            }
        }

        // ── MAIN CONTENT ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingM

            // LEFT: Control panel
            ColumnLayout {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                spacing: Theme.spacingM

                // Control card
                Rectangle {
                    Layout.fillWidth: true
                    height: controlCol.implicitHeight + Theme.spacingL * 2
                    color: Colors.bg2
                    radius: Theme.radiusMedium
                    border.color: Simulator && Simulator.running ? Colors.warning : Colors.border
                    border.width: Simulator && Simulator.running ? 2 : 1

                    ColumnLayout {
                        id: controlCol
                        anchors { fill: parent; margins: Theme.spacingL }
                        spacing: Theme.spacingM

                        Text {
                            text: "SIMULATOR CONTROLS"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.letterSpacing: 1
                        }

                        // Phase display
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            color: Colors.bg3
                            radius: Theme.radiusSmall
                            border.color: Colors.border
                            border.width: 1

                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                                spacing: Theme.spacingS

                                Text {
                                    text: "PHASE:"
                                    color: Colors.textSecondary
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    text: Simulator && Simulator.running ? Simulator.simState : "IDLE"
                                    color: Simulator && Simulator.running ? Colors.warning : Colors.textDisabled
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                // Animated dot
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: Simulator && Simulator.running ? Colors.ok : Colors.textDisabled
                                    SequentialAnimation on opacity {
                                        running: Simulator && Simulator.running
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 400 }
                                        NumberAnimation { to: 1.0; duration: 400 }
                                    }
                                }
                            }
                        }

                        // Progress bar
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "SIMULATION PROGRESS"
                                    color: Colors.textSecondary
                                    font.pixelSize: Theme.fontSizeTiny
                                    font.family: Theme.fontFamily
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Simulator ? Math.round(Simulator.progress * 100) + "%" : "0%"
                                    color: Colors.accent
                                    font.pixelSize: Theme.fontSizeTiny
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                color: Colors.bg4
                                radius: 4

                                Rectangle {
                                    width: parent.width * (Simulator ? Simulator.progress : 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Colors.ok
                                    Behavior on width { NumberAnimation { duration: 300 } }
                                }
                            }
                        }

                        // Action buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS

                            IGButton {
                                text: Simulator && Simulator.running ? "STOP SIMULATION" : "START SIMULATION"
                                implicitWidth: 160
                                danger: Simulator && Simulator.running
                                baseColor: Simulator && Simulator.running ? "" : Colors.ok
                                textColor: Simulator && Simulator.running ? Colors.textBright : Colors.bg0
                                onClicked: {
                                    if (Simulator) {
                                        Simulator.running ? Simulator.stop() : Simulator.start()
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // Sub-controls (only when running)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS
                            visible: Simulator && Simulator.running

                            IGButton {
                                text: "ARM"
                                implicitWidth: 70
                                baseColor: Colors.warning
                                textColor: Colors.bg0
                                enabled: Simulator && Simulator.running
                                onClicked: if (Simulator) Simulator.arm()
                            }
                            IGButton {
                                text: "DISARM"
                                implicitWidth: 80
                                danger: true
                                enabled: Simulator && Simulator.running
                                onClicked: if (Simulator) Simulator.disarm()
                            }
                            IGButton {
                                text: "TAKEOFF"
                                implicitWidth: 85
                                enabled: Simulator && Simulator.running
                                onClicked: if (Simulator) Simulator.takeoff(10.0)
                            }
                            IGButton {
                                text: "LAND"
                                implicitWidth: 70
                                enabled: Simulator && Simulator.running
                                onClicked: if (Simulator) Simulator.land()
                            }
                        }
                    }
                }

                // SIMULATED VEHICLE info panel
                Rectangle {
                    Layout.fillWidth: true
                    height: vehInfoCol.implicitHeight + Theme.spacingL * 2
                    color: Colors.bg2
                    radius: Theme.radiusMedium
                    border.color: Colors.border
                    border.width: 1

                    ColumnLayout {
                        id: vehInfoCol
                        anchors { fill: parent; margins: Theme.spacingL }
                        spacing: Theme.spacingS

                        Text {
                            text: "SIMULATED VEHICLE"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.letterSpacing: 1
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: Theme.spacingM
                            rowSpacing: 6

                            Text { text: "Vehicle Type:"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                            Text { text: "ArduCopter (Quadrotor)"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }

                            Text { text: "System ID:"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                            Text {
                                text: VehicleManager && VehicleManager.activeVehicle
                                      ? String(VehicleManager.activeVehicle.sysId) : "1"
                                color: Colors.accent
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.bold: true
                            }

                            Text { text: "Component ID:"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                            Text {
                                text: VehicleManager && VehicleManager.activeVehicle
                                      ? String(VehicleManager.activeVehicle.compId) : "1"
                                color: Colors.accent
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                            }

                            Text { text: "Status:"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                            Text {
                                text: Simulator && Simulator.running ? "● ACTIVE" : "○ STOPPED"
                                color: Simulator && Simulator.running ? Colors.ok : Colors.textDisabled
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }
                    }
                }

                // Disclaimer
                Rectangle {
                    Layout.fillWidth: true
                    height: disclaimer.implicitHeight + 20
                    color: "#1a0000"
                    radius: Theme.radiusSmall
                    border.color: Colors.critical
                    border.width: 1

                    Text {
                        id: disclaimer
                        anchors { fill: parent; margins: 10 }
                        text: "⚠  THIS IS A SOFTWARE SIMULATION — NO REAL AIRCRAFT\n" +
                              "No motors, propellers, or hardware are involved.\n" +
                              "Telemetry values are generated synthetically."
                        color: Colors.critical
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        wrapMode: Text.WordWrap
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // RIGHT: Live telemetry panel
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.spacingM

                Text {
                    text: "SIMULATED TELEMETRY"
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.letterSpacing: 1
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Theme.spacingS
                    rowSpacing: Theme.spacingS

                    TelemetryCard {
                        label: "LATITUDE"
                        value: tel ? tel.latitude.toFixed(6) : "—"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "LONGITUDE"
                        value: tel ? tel.longitude.toFixed(6) : "—"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "ALTITUDE"
                        value: tel ? tel.altitudeRel.toFixed(1) : "—"
                        unit: "m"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "GND SPEED"
                        value: tel ? tel.groundSpeed.toFixed(1) : "—"
                        unit: "m/s"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "HEADING"
                        value: tel ? tel.heading.toFixed(0) : "—"
                        unit: "°"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "BATTERY"
                        value: tel ? tel.batteryRemaining + "%" : "—"
                        valueColor: tel && tel.batteryRemaining < 20 ? Colors.critical
                                  : (tel && tel.batteryRemaining < 40 ? Colors.warning : Colors.ok)
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "ROLL"
                        value: tel ? tel.roll.toFixed(1) : "—"
                        unit: "°"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "PITCH"
                        value: tel ? tel.pitch.toFixed(1) : "—"
                        unit: "°"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "CLIMB RATE"
                        value: tel ? tel.climbRate.toFixed(1) : "—"
                        unit: "m/s"
                        Layout.fillWidth: true
                    }
                    TelemetryCard {
                        label: "FLIGHT MODE"
                        value: tel ? tel.flightMode : "—"
                        Layout.fillWidth: true
                    }
                }

                // Armed state indicator
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: tel && tel.armed ? "#300000" : "#002000"
                    radius: Theme.radiusSmall
                    border.color: tel && tel.armed ? Colors.critical : Colors.ok
                    border.width: 2

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                        spacing: Theme.spacingS

                        Rectangle {
                            width: 12; height: 12; radius: 6
                            color: tel && tel.armed ? Colors.critical : Colors.ok
                            SequentialAnimation on opacity {
                                running: tel && tel.armed
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 400 }
                                NumberAnimation { to: 1.0; duration: 400 }
                            }
                        }

                        Text {
                            text: tel ? (tel.armed ? "VEHICLE ARMED" : "VEHICLE DISARMED / SAFE") : "NO LINK"
                            color: tel && tel.armed ? Colors.critical : Colors.ok
                            font.pixelSize: Theme.fontSizeNormal
                            font.family: Theme.fontFamily
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
