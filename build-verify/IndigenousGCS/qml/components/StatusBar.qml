import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    height: Theme.statusBarHeight
    color:  Colors.bg1

    // Top border separator
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: Colors.border
    }

    property var tel: VehicleManager && VehicleManager.activeVehicle
                      ? VehicleManager.activeVehicle.telemetry : null

    // Track last heartbeat time
    property real lastHeartbeatSec: 0
    property string timeSinceLink: "NO LINK"

    Connections {
        target: MAVLinkManager
        function onHeartbeatReceived() {
            root.lastHeartbeatSec = Date.now() / 1000
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.lastHeartbeatSec > 0) {
                const diff = Math.round(Date.now() / 1000 - root.lastHeartbeatSec)
                if (diff > 5) {
                    root.timeSinceLink = diff + "s ago"
                } else {
                    root.timeSinceLink = diff + "s"
                }
            } else {
                root.timeSinceLink = "NO LINK"
            }
        }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
        spacing: 0

        // GPS
        StatusPill {
            label: "GPS"
            value: tel ? tel.gpsSatCount + "sat  fix:" + tel.gpsFixType : "—"
            valueColor: tel && tel.gpsSatCount >= 6 ? Colors.ok
                      : (tel && tel.gpsSatCount >= 3 ? Colors.warning : Colors.critical)
            icon: tel && tel.gpsFixType >= 3 ? "●" : "○"
            iconColor: tel && tel.gpsFixType >= 3 ? Colors.ok : Colors.critical
        }
        Divider {}

        // Battery
        StatusPill {
            label: "BAT"
            value: tel ? tel.batteryVoltage.toFixed(1) + "V  " + tel.batteryRemaining + "%" : "—"
            valueColor: tel && tel.batteryRemaining < 20 ? Colors.critical
                      : (tel && tel.batteryRemaining < 40 ? Colors.warning : Colors.ok)
        }
        Divider {}

        // Link quality
        StatusPill {
            label: "LINK"
            value: MAVLinkManager ? MAVLinkManager.packetsPerSecond.toFixed(0) + "Hz" : "—"
            valueColor: MAVLinkManager && MAVLinkManager.packetsPerSecond > 0 ? Colors.ok : Colors.critical
        }
        Divider {}

        // Flight mode
        StatusPill {
            label: "MODE"
            value: tel ? tel.flightMode : "—"
            valueColor: Colors.accent
        }
        Divider {}

        // Armed state
        StatusPill {
            label: "ARM"
            value: tel ? (tel.armed ? "ARMED" : "SAFE") : "—"
            valueColor: tel && tel.armed ? Colors.critical : Colors.ok
        }
        Divider {}

        // Altitude
        StatusPill {
            label: "ALT"
            value: tel ? tel.altitudeRel.toFixed(1) + "m" : "—"
            valueColor: Colors.accentBlue
        }
        Divider {}

        // Ground speed
        StatusPill {
            label: "SPD"
            value: tel ? tel.groundSpeed.toFixed(1) + "m/s" : "—"
            valueColor: Colors.accentBlue
        }
        Divider {}

        // Heading
        StatusPill {
            label: "HDG"
            value: tel ? tel.heading.toFixed(0) + "°" : "—"
            valueColor: Colors.textPrimary
        }
        Divider {}

        // CPU load
        StatusPill {
            label: "CPU"
            value: tel && tel.cpuLoad !== undefined ? tel.cpuLoad + "‰" : "—"
            valueColor: tel && tel.cpuLoad !== undefined && tel.cpuLoad > 800 ? Colors.warning : Colors.textPrimary
        }
        Divider {}

        // Last heartbeat
        StatusPill {
            label: "HB"
            value: root.timeSinceLink
            valueColor: root.timeSinceLink === "NO LINK" ? Colors.critical
                      : (root.lastHeartbeatSec > 0 && (Date.now() / 1000 - root.lastHeartbeatSec) > 3
                         ? Colors.warning : Colors.ok)
        }

        Item { Layout.fillWidth: true }

        // Dedication credit, centred in the free space of the status bar.
        Text {
            text: "MADE WITH DEDICATION BY GARVIT PANT"
            color: Colors.accent
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
            font.bold: true
            font.letterSpacing: 1.5
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Dropped packets warning
        Text {
            visible: MAVLinkManager && MAVLinkManager.droppedPackets > 0
            text: "⚠ " + (MAVLinkManager ? MAVLinkManager.droppedPackets.toFixed(0) : "0") + " dropped"
            color: Colors.warning
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
        }

        Item { width: Theme.spacingM }

        // Version
        Text {
            text: "v1.0.0"
            color: Colors.textDisabled
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
        }

        Item { width: Theme.spacingS }

        // Clock
        Text {
            id: clk
            color: Colors.textDisabled
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clk.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd  hh:mm:ss")
            }
            Component.onCompleted: text = Qt.formatDateTime(new Date(), "yyyy-MM-dd  hh:mm:ss")
        }
    }

    component Divider: Rectangle {
        width: 1; height: 14
        color: Colors.border
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 4
        Layout.rightMargin: 4
    }

    component StatusPill: Row {
        spacing: 4
        property string label
        property string value
        property color  valueColor: Colors.textPrimary
        property string icon: ""
        property color  iconColor: Colors.textPrimary

        Text {
            visible: icon !== ""
            text: icon
            color: iconColor
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: label
            color: Colors.textDisabled
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: value
            color: valueColor
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
