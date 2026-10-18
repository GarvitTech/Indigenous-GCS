import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    color: Colors.bg2
    radius: Theme.radiusSmall
    border.color: Colors.border
    border.width: 1
    clip: true

    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null

    ListModel { id: messages }

    Connections {
        target: vehicle
        function onStatusTextReceived(severity, text) {
            const colors = [Colors.emergency, Colors.emergency, Colors.critical,
                            Colors.critical, Colors.warning, Colors.info,
                            Colors.textPrimary, Colors.textSecondary]
            const labels = ["EMERG","ALERT","CRIT","ERROR","WARN","NOTICE","INFO","DEBUG"]
            messages.insert(0, {
                sev: severity,
                label: labels[Math.min(severity, 7)],
                msg: text,
                clr: colors[Math.min(severity, 7)]
            })
            if (messages.count > 50) messages.remove(50)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true; height: 28
            color: Colors.bg3
            Text {
                anchors { left: parent.left; leftMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                text: "STATUS MESSAGES"
                color: Colors.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.letterSpacing: 1
            }
            Text {
                anchors { right: parent.right; rightMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                text: messages.count + " msgs"
                color: Colors.textDisabled
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: messages
            clip: true
            delegate: RowLayout {
                width: ListView.view.width
                height: 22
                spacing: Theme.spacingS
                Rectangle { width: 4; height: parent.height; color: model.clr }
                Text {
                    text: "[" + model.label + "]"
                    color: model.clr
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.preferredWidth: 60
                }
                Text {
                    text: model.msg
                    color: Colors.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}
