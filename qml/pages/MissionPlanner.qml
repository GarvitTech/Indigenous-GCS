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

        // Toolbar
        RowLayout {
            spacing: Theme.spacingS
            Text { text: "MISSION PLANNER"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            IGButton { text: "NEW";      implicitWidth: 70; onClicked: MissionManager.mission.clear() }
            IGButton { text: "VALIDATE"; implicitWidth: 80; onClicked: validateMission() }
            IGButton { text: "UPLOAD";   implicitWidth: 80; enabled: vehicle !== null
                onClicked: { if (vehicle) MissionManager.uploadMission(vehicle.sysId, vehicle.compId) } }
            IGButton { text: "DOWNLOAD"; implicitWidth: 90; enabled: vehicle !== null
                onClicked: { if (vehicle) MissionManager.downloadMission(vehicle.sysId, vehicle.compId) } }
            IGButton { text: "CLEAR FC"; implicitWidth: 80; danger: true; enabled: vehicle !== null
                onClicked: { if (vehicle) MissionManager.clearMission(vehicle.sysId, vehicle.compId) } }
        }

        // Transfer progress
        Rectangle {
            Layout.fillWidth: true; height: 24
            color: Colors.bg2; radius: Theme.radiusSmall
            border.color: Colors.border; border.width: 1
            visible: MissionManager.transferState !== 0

            Rectangle {
                width: parent.width * MissionManager.transferProgress / 100
                height: parent.height; radius: parent.radius
                color: MissionManager.transferState === 3 ? Colors.ok
                     : MissionManager.transferState === 4 ? Colors.critical : Colors.accent
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            Text {
                anchors.centerIn: parent
                text: {
                    switch(MissionManager.transferState) {
                    case 1: return "Uploading... " + MissionManager.transferProgress + "%"
                    case 2: return "Downloading... " + MissionManager.transferProgress + "%"
                    case 3: return "Transfer complete"
                    case 4: return "Transfer failed"
                    default: return ""
                    }
                }
                color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
            }
        }

        // Add waypoint form
        Rectangle {
            Layout.fillWidth: true; height: 50
            color: Colors.bg2; radius: Theme.radiusSmall
            border.color: Colors.border; border.width: 1

            RowLayout {
                anchors { fill: parent; margins: Theme.spacingS }
                spacing: Theme.spacingS

                Text { text: "ADD WP:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }

                function labeledField(lbl, ph) {
                    return null // handled inline below
                }

                TextField {
                    id: latField; placeholderText: "Latitude"; implicitWidth: 120; implicitHeight: 30
                    color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                    background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                }
                TextField {
                    id: lonField; placeholderText: "Longitude"; implicitWidth: 120; implicitHeight: 30
                    color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                    background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                }
                TextField {
                    id: altField; placeholderText: "Alt (m)"; text: "10"; implicitWidth: 70; implicitHeight: 30
                    color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                    background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                }
                IGButton {
                    text: "ADD"; implicitWidth: 60; implicitHeight: 30
                    onClicked: {
                        const lat = parseFloat(latField.text)
                        const lon = parseFloat(lonField.text)
                        const alt = parseFloat(altField.text)
                        if (!isNaN(lat) && !isNaN(lon) && !isNaN(alt))
                            MissionManager.mission.addWaypoint(lat, lon, alt)
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: MissionManager.mission ? MissionManager.mission.count + " waypoints" : "0 waypoints"
                    color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                }
            }
        }

        // Waypoint table
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: Colors.bg2; radius: Theme.radiusSmall
            border.color: Colors.border; border.width: 1

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true; height: 28; color: Colors.bg3
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingS }
                        spacing: 0
                        Repeater {
                            model: ["#","COMMAND","LATITUDE","LONGITUDE","ALTITUDE","ACTIONS"]
                            Text {
                                text: modelData; color: Colors.textSecondary
                                font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                                Layout.preferredWidth: index === 0 ? 40 : index === 5 ? 80 : 130
                            }
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: MissionManager.mission ? MissionManager.mission.count : 0
                    clip: true
                    delegate: Rectangle {
                        width: ListView.view.width; height: 32
                        color: index % 2 === 0 ? Colors.bg2 : Colors.bg3

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spacingS }
                            spacing: 0
                            Text { text: index; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 40 }
                            Text { text: "Waypoint"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 130 }
                            Text { text: "—"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 130 }
                            Text { text: "—"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 130 }
                            Text { text: "—"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 130 }
                            IGButton {
                                text: "✕"; implicitWidth: 30; implicitHeight: 24; danger: true
                                onClicked: MissionManager.mission.removeWaypoint(index)
                            }
                        }
                    }
                }
            }
        }
    }

    function validateMission() {
        if (!MissionManager.mission) return
        const errors = MissionManager.mission.validate()
        validationDialog.errors = errors
        validationDialog.open()
    }

    Dialog {
        id: validationDialog
        property var errors: []
        title: errors.length === 0 ? "Mission Valid" : "Validation Errors"
        modal: true; anchors.centerIn: Overlay.overlay
        background: Rectangle { color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1 }
        Text {
            text: validationDialog.errors.length === 0 ? "✓ Mission is valid." : validationDialog.errors.join("\n")
            color: validationDialog.errors.length === 0 ? Colors.ok : Colors.critical
            font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily; wrapMode: Text.WordWrap; width: 300
        }
        standardButtons: Dialog.Ok
    }
}
