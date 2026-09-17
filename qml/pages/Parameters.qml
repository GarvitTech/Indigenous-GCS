import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0
    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        RowLayout {
            spacing: Theme.spacingS
            Text { text: "PARAMETERS"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            Text {
                text: ParameterManager.loading ? "Loading..." : ParameterManager.receivedCount + " / " + ParameterManager.totalCount
                color: ParameterManager.loading ? Colors.warning : Colors.ok
                font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
            }
            IGButton {
                text: "REFRESH"; implicitWidth: 90; enabled: vehicle !== null
                onClicked: { if (vehicle) ParameterManager.requestAll(vehicle.sysId, vehicle.compId) }
            }
        }

        // Search
        TextField {
            id: searchField
            Layout.fillWidth: true; implicitHeight: 32
            placeholderText: "Search parameters..."
            color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
            background: Rectangle { color: Colors.bg2; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
        }

        // Loading bar
        Rectangle {
            Layout.fillWidth: true; height: 4
            color: Colors.bg3; radius: 2; visible: ParameterManager.loading
            Rectangle {
                width: ParameterManager.totalCount > 0
                       ? parent.width * ParameterManager.receivedCount / ParameterManager.totalCount : 0
                height: parent.height; radius: parent.radius; color: Colors.accent
                Behavior on width { NumberAnimation { duration: 100 } }
            }
        }

        // Table header
        Rectangle {
            Layout.fillWidth: true; height: 28; color: Colors.bg3
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.spacingS }
                spacing: 0
                Repeater {
                    model: ["PARAMETER","VALUE","TYPE"]
                    Text { text: modelData; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        Layout.preferredWidth: index === 0 ? 220 : index === 1 ? 140 : 80 }
                }
            }
        }

        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            model: ParameterManager.parameterNames().filter(n => n.toLowerCase().includes(searchField.text.toLowerCase()))

            delegate: Rectangle {
                width: ListView.view.width; height: 30
                color: index % 2 === 0 ? Colors.bg2 : Colors.bg3

                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                    spacing: 0

                    Text { text: modelData; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 220; elide: Text.ElideRight }

                    TextField {
                        id: valField
                        text: ParameterManager.getParameter(modelData) !== undefined ? ParameterManager.getParameter(modelData).toString() : "—"
                        color: Colors.accent; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                        implicitWidth: 130; implicitHeight: 24
                        background: Rectangle { color: Colors.bg3; radius: 3; border.color: valField.activeFocus ? Colors.accent : Colors.border; border.width: 1 }
                        onEditingFinished: {
                            if (vehicle) {
                                const v = parseFloat(text)
                                if (!isNaN(v)) ParameterManager.setParameter(vehicle.sysId, vehicle.compId, modelData, v)
                            }
                        }
                    }

                    Text { text: "float"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 80 }
                }
            }
        }
    }
}
