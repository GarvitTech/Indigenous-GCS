import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    spacing: Theme.spacingS

    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null

    Text { text: "MODE:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }

    ComboBox {
        id: combo
        enabled: vehicle !== null
        model: ["Stabilize","Alt Hold","Loiter","Auto","Guided","RTL","Land","PosHold","Brake"]
        implicitWidth: 120
        implicitHeight: 30

        background: Rectangle {
            color: Colors.bg3; radius: Theme.radiusSmall
            border.color: Colors.border; border.width: 1
        }
        contentItem: Text {
            leftPadding: 8
            text: combo.displayText
            color: Colors.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            verticalAlignment: Text.AlignVCenter
        }
        delegate: ItemDelegate {
            width: combo.width
            contentItem: Text {
                text: modelData
                color: Colors.textPrimary
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
            }
            background: Rectangle { color: hovered ? Colors.bg3 : Colors.bg2 }
        }
        popup: Popup {
            y: combo.height; width: combo.width; padding: 0
            background: Rectangle { color: Colors.bg2; border.color: Colors.border; border.width: 1 }
            contentItem: ListView { model: combo.delegateModel; clip: true; implicitHeight: contentHeight }
        }
    }

    IGButton {
        text: "SET"
        implicitWidth: 50
        implicitHeight: 30
        enabled: vehicle !== null
        onClicked: {
            if (vehicle) vehicle.setFlightMode(combo.currentText)
        }
    }
}
