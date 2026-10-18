import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    property string label
    property string value:      "—"
    property string unit:       ""
    property color  valueColor: Colors.accent

    color:  Colors.bg2
    radius: Theme.radiusSmall
    border.color: Colors.border
    border.width: 1
    implicitWidth:  120
    implicitHeight: 52

    Column {
        anchors { fill: parent; margins: 6 }
        spacing: 2

        Text {
            text: label
            color: Colors.textDisabled
            font.pixelSize: Theme.fontSizeTiny
            font.family: Theme.fontFamily
            font.letterSpacing: 1
        }

        Row {
            spacing: 3
            Text {
                text: value
                color: valueColor
                font.pixelSize: Theme.fontSizeMedium
                font.family: Theme.fontFamily
                font.bold: true
            }
            Text {
                text: unit
                color: Colors.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                visible: unit !== ""
                anchors.baseline: parent.children[0].baseline
            }
        }
    }
}
