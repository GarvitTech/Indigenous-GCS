import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    width: Theme.sideBarWidth
    color: Colors.bg1

    property int currentIndex: 0
    signal pageSelected(int index)

    Rectangle { anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                width: 1; color: Colors.border }

    readonly property var pages: [
        { icon: "⊞", label: "DASHBOARD",   sub: "Overview" },
        { icon: "✈", label: "FLIGHT DATA", sub: "HUD · Map" },
        { icon: "◎", label: "MISSION",     sub: "Waypoints" },
        { icon: "⚙", label: "PARAMETERS",  sub: "FC Config" },
        { icon: "≋", label: "INAV CONFIG", sub: "MSP Setup" },
        { icon: "⊕", label: "CALIBRATION", sub: "Sensors" },
        { icon: "◈", label: "VEHICLE",     sub: "Setup" },
        { icon: "↑", label: "FIRMWARE",    sub: "Flash · OTA" },
        { icon: "▷", label: "SIMULATION",  sub: "SITL" },
        { icon: "☰", label: "LOGS",        sub: "Flight Records" },
        { icon: "⊘", label: "DIAGNOSTICS", sub: "MAVLink" },
        { icon: "⚙", label: "SETTINGS",    sub: "Application" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Section header
        Rectangle {
            Layout.fillWidth: true; height: 28; color: Colors.bg2
            Text {
                anchors { left: parent.left; leftMargin: Theme.spacingM; verticalCenter: parent.verticalCenter }
                text: "NAVIGATION"; color: Colors.textDisabled
                font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 2
            }
        }

        Repeater {
            model: root.pages
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 46
                color: root.currentIndex === index ? Colors.accentGlow : (hov.containsMouse ? Colors.bg2 : "transparent")

                // Active left indicator
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 3
                    color: root.currentIndex === index ? Colors.accent : "transparent"
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: Theme.spacingS }
                    spacing: Theme.spacingS

                    Text {
                        text: modelData.icon
                        color: root.currentIndex === index ? Colors.accent : Colors.textSecondary
                        font.pixelSize: 16
                        Layout.preferredWidth: 20
                    }

                    Column {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: modelData.label
                            color: root.currentIndex === index ? Colors.accent : Colors.textPrimary
                            font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                            font.bold: root.currentIndex === index
                        }
                        Text {
                            text: modelData.sub
                            color: Colors.textDisabled
                            font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily
                        }
                    }
                }

                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border; opacity: 0.4 }

                HoverHandler { id: hov }
                TapHandler { onTapped: { root.currentIndex = index; root.pageSelected(index) } }
            }
        }

        Item { Layout.fillHeight: true }

        // Bottom vehicle status
        Rectangle {
            Layout.fillWidth: true; height: 60
            color: Colors.bg2
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: Colors.border }

            property var v: VehicleManager ? VehicleManager.activeVehicle : null

            Column {
                anchors { fill: parent; margins: Theme.spacingS }
                spacing: 3
                Text {
                    text: parent.parent.v ? "VEHICLE  SYS:" + parent.parent.v.sysId : "NO VEHICLE"
                    color: parent.parent.v ? Colors.textSecondary : Colors.textDisabled
                    font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1
                }
                Text {
                    property var t: parent.parent.parent.v ? parent.parent.parent.v.telemetry : null
                    text: t ? (t.armed ? "● ARMED  " + t.flightMode : "● DISARMED") : "—"
                    color: {
                        var t2 = parent.parent.parent.v ? parent.parent.parent.v.telemetry : null
                        return t2 && t2.armed ? Colors.critical : Colors.ok
                    }
                    font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                }
                Text {
                    property var t: parent.parent.parent.v ? parent.parent.parent.v.telemetry : null
                    text: t ? "ALT " + t.altitudeRel.toFixed(1) + "m  SPD " + t.groundSpeed.toFixed(1) + "m/s" : "—"
                    color: Colors.textSecondary; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily
                }
            }
        }

        // IAF watermark
        Rectangle {
            Layout.fillWidth: true; height: 24; color: Colors.bg1
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: Colors.border }
            Text {
                anchors.centerIn: parent
                text: "भारतीय वायु सेना"
                color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamilyUI
            }
        }
    }
}
