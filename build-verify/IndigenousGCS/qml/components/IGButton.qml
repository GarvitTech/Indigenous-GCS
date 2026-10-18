import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Button {
    id: root
    property bool danger:    false
    property bool secondary: false
    property bool active:    false
    property color baseColor: "transparent"
    property color textColor: "transparent"

    implicitHeight: 30
    implicitWidth:  100

    background: Rectangle {
        radius: Theme.radiusSmall
        color: {
            if (root.baseColor.a > 0) return root.pressed ? Qt.darker(root.baseColor, 1.2) : (root.hovered ? Qt.lighter(root.baseColor, 1.15) : root.baseColor)
            if (root.danger)     return root.pressed ? "#cc0020" : (root.hovered ? "#ff1744" : "#8b0000")
            if (root.active)     return root.pressed ? Colors.accentDim : Colors.accent
            if (root.secondary)  return root.pressed ? Colors.bg4 : (root.hovered ? Colors.bg3 : Colors.bg2)
            return root.pressed ? Colors.accentDim : (root.hovered ? "#cc7700" : Colors.bg3)
        }
        border.color: root.danger ? Colors.critical : (root.active ? Colors.accent : (root.secondary ? Colors.border : Colors.accent))
        border.width: 1
        Behavior on color { ColorAnimation { duration: 80 } }
    }

    contentItem: Text {
        text:                root.text
        color:               root.textColor.a > 0 ? root.textColor : (root.danger ? Colors.textBright : (root.active ? Colors.bg0 : Colors.accent))
        font.pixelSize:      Theme.fontSizeSmall
        font.family:         Theme.fontFamily
        font.bold:           true
        font.letterSpacing:  0.5
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
    }
}
