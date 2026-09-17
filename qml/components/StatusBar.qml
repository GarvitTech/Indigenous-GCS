import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    height: Theme.statusBarHeight
    color:  Colors.bg1

    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: Colors.border }

    property var tel: VehicleManager && VehicleManager.activeVehicle ? VehicleManager.activeVehicle.telemetry : null

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
        spacing: 0

        // Link
        StatusPill { label: "LINK"; value: MAVLinkManager ? MAVLinkManager.packetsPerSecond.toFixed(0)+"Hz" : "—"
            valueColor: MAVLinkManager && MAVLinkManager.packetsPerSecond > 0 ? Colors.ok : Colors.critical }
        Divider {}
        // GPS
        StatusPill { label: "GPS"; value: tel ? tel.gpsSatCount+"sat  fix:"+tel.gpsFixType : "—"
            valueColor: tel && tel.gpsSatCount >= 6 ? Colors.ok : Colors.warning }
        Divider {}
        // Battery
        StatusPill { label: "BAT"; value: tel ? tel.batteryVoltage.toFixed(1)+"V  "+tel.batteryRemaining+"%" : "—"
            valueColor: tel && tel.batteryRemaining < 20 ? Colors.critical : (tel && tel.batteryRemaining < 40 ? Colors.warning : Colors.ok) }
        Divider {}
        // Altitude
        StatusPill { label: "ALT"; value: tel ? tel.altitudeRel.toFixed(1)+"m" : "—"; valueColor: Colors.accentBlue }
        Divider {}
        // Speed
        StatusPill { label: "SPD"; value: tel ? tel.groundSpeed.toFixed(1)+"m/s" : "—"; valueColor: Colors.accentBlue }
        Divider {}
        // Heading
        StatusPill { label: "HDG"; value: tel ? tel.heading.toFixed(0)+"°" : "—"; valueColor: Colors.textPrimary }
        Divider {}
        // Mode
        StatusPill { label: "MODE"; value: tel ? tel.flightMode : "—"; valueColor: Colors.accent }
        Divider {}
        // Armed
        StatusPill { label: "ARM"; value: tel ? (tel.armed ? "ARMED" : "SAFE") : "—"
            valueColor: tel && tel.armed ? Colors.critical : Colors.ok }

        Item { Layout.fillWidth: true }

        // Dropped packets warning
        Text {
            visible: MAVLinkManager && MAVLinkManager.droppedPackets > 0
            text: "⚠ " + (MAVLinkManager ? MAVLinkManager.droppedPackets.toFixed(0) : "0") + " dropped"
            color: Colors.warning; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily
        }

        Item { width: Theme.spacingM }

        Text {
            id: clk; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd  hh:mm:ss") }
            Component.onCompleted: text = Qt.formatDateTime(new Date(), "yyyy-MM-dd  hh:mm:ss")
        }
    }

    component Divider: Rectangle { width: 1; height: 14; color: Colors.border; Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 4; Layout.rightMargin: 4 }

    component StatusPill: Row {
        spacing: 4
        property string label
        property string value
        property color  valueColor: Colors.textPrimary
        Text { text: label; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
        Text { text: value; color: valueColor; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
    }
}
