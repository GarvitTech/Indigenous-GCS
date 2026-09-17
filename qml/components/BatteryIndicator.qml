import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    spacing: 6
    property var telemetry: null

    property real pct: telemetry ? telemetry.batteryRemaining : -1
    property real volts: telemetry ? telemetry.batteryVoltage : 0

    property color barColor: pct > 50 ? Colors.ok : pct > 20 ? Colors.warning : Colors.critical

    Text { text: "BAT:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }

    Rectangle {
        width: 36; height: 14; radius: 2
        color: Colors.bg3; border.color: Colors.border; border.width: 1
        Rectangle {
            width: pct >= 0 ? parent.width * pct / 100 : 0
            height: parent.height; radius: 2
            color: barColor
            Behavior on width { NumberAnimation { duration: 300 } }
        }
        // Battery tip
        Rectangle { anchors { right: parent.right; rightMargin: -4; verticalCenter: parent.verticalCenter }
            width: 4; height: 8; radius: 1; color: Colors.border }
    }

    Text {
        text: pct >= 0 ? pct + "%" : "—"
        color: barColor
        font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
    }
    Text {
        text: volts > 0 ? volts.toFixed(2) + "V" : ""
        color: Colors.textSecondary
        font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
    }
}
