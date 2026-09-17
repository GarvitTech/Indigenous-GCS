import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    spacing: 6

    property int    connState:   ConnectionManager ? ConnectionManager.connectionState : 0
    property bool   fcDetected:  MAVLinkManager ? MAVLinkManager.hasVehicle : false
    property string description: ConnectionManager ? ConnectionManager.description : "Disconnected"

    // 0=Disconnected 1=Connecting 2=Connected 3=Reconnecting 4=Error
    readonly property color dotColor: {
        switch (connState) {
        case 2:  return Colors.ok
        case 1:  return Colors.warning
        case 3:  return Colors.warning
        case 4:  return Colors.critical
        default: return Colors.textDisabled
        }
    }
    readonly property string stateLabel: {
        switch (connState) {
        case 2:  return "CONNECTED"
        case 1:  return "CONNECTING"
        case 3:  return "RECONNECTING"
        case 4:  return "ERROR"
        default: return "DISCONNECTED"
        }
    }

    Rectangle {
        width: 8; height: 8; radius: 4
        color: dotColor
        SequentialAnimation on opacity {
            running: connState === 1 || connState === 3
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 600 }
            NumberAnimation { to: 1.0; duration: 600 }
        }
    }

    Text {
        text: fcDetected ? "FC DETECTED" : stateLabel
        color: dotColor
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
        font.bold: true
    }

    Text {
        text: fcDetected ? "Heartbeat received" : description
        color: Colors.textSecondary
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
        visible: connState === 2
    }
}
