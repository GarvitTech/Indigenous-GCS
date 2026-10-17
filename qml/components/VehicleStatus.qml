import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../theme"

RowLayout {
    spacing: Theme.spacingS
    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null

    IGButton {
        text: "ARM"
        enabled: vehicle !== null && !vehicle.simulated && !vehicle.armed
        baseColor: Colors.warning
        textColor: Colors.bg0
        implicitWidth: 80
        onClicked: confirmDialog.armMode = true, confirmDialog.open()
    }

    IGButton {
        text: "DISARM"
        enabled: vehicle !== null && !vehicle.simulated && vehicle.armed
        danger: true
        implicitWidth: 80
        onClicked: confirmDialog.armMode = false, confirmDialog.open()
    }

    Dialog {
        id: confirmDialog
        property bool armMode: true
        title: armMode ? "Confirm ARM" : "Confirm DISARM"
        modal: true
        anchors.centerIn: Overlay.overlay
        background: Rectangle { color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1 }

        Text {
            text: confirmDialog.armMode
                  ? "⚠  Are you sure you want to ARM the vehicle?\nEnsure area is clear of people and obstacles."
                  : "Disarm the vehicle?"
            color: Colors.textPrimary
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
            wrapMode: Text.WordWrap
            width: 300
        }

        footer: RowLayout {
            spacing: Theme.spacingS
            Item { Layout.fillWidth: true }
            IGButton {
                text: "Cancel"
                baseColor: Colors.textDisabled
                onClicked: confirmDialog.close()
            }
            IGButton {
                text: confirmDialog.armMode ? "ARM" : "DISARM"
                danger: !confirmDialog.armMode
                baseColor: confirmDialog.armMode ? Colors.warning : Colors.critical
                onClicked: {
                    if (vehicle && !vehicle.simulated) {
                        if (confirmDialog.armMode) vehicle.arm()
                        else vehicle.disarm()
                    }
                    confirmDialog.close()
                }
            }
        }
    }
}
