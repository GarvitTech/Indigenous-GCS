import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../theme"

/*
 * Connection dialog — serial port and UDP link setup.
 *
 * Drives the real ConnectionManager; every button here maps to an actual
 * open()/close() on a transport. No simulated state.
 */
Popup {
    id: root

    width: 460
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    padding: 0

    readonly property bool linkUp: ConnectionManager && ConnectionManager.isConnected

    background: Rectangle {
        color: Colors.bg1
        border.color: Colors.borderHi
        border.width: 1
        radius: Theme.radiusMedium
    }

    onOpened: {
        refreshPorts()
        if (ConnectionManager && ConnectionManager.description)
            statusText.text = ConnectionManager.description
    }

    function refreshPorts() {
        portCombo.model = ConnectionManager ? ConnectionManager.availableSerialPorts() : []
    }

    function attemptConnect() {
        if (!ConnectionManager)
            return
        if (tabBar.currentIndex === 0) {
            const port = portCombo.currentText
            if (!port) {
                statusText.text = "No serial port selected"
                return
            }
            ConnectionManager.connectSerial(port, parseInt(baudCombo.currentText))
        } else {
            ConnectionManager.connectUDP(udpHost.text, parseInt(udpPort.text))
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            color: Colors.bg2
            radius: Theme.radiusMedium

            Rectangle {   // square off the bottom corners
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Theme.radiusMedium
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingS

                Text {
                    text: "LINK SETUP"
                    color: Colors.accent
                    font.pixelSize: Theme.fontSizeNormal
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.letterSpacing: 2
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: root.linkUp ? Colors.ok : Colors.critical
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.linkUp ? "CONNECTED" : "DISCONNECTED"
                    color: root.linkUp ? Colors.ok : Colors.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                }

                IGButton {
                    text: "✕"
                    implicitWidth: 28
                    implicitHeight: 24
                    onClicked: root.close()
                }
            }
        }

        // ── Tabs ──────────────────────────────────────────────────────────
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.margins: Theme.spacingM
            spacing: 2

            background: Rectangle { color: "transparent" }

            TabButton {
                text: "SERIAL"
                implicitWidth: 110
                contentItem: Text {
                    text: parent.text
                    color: tabBar.currentIndex === 0 ? Colors.accent : Colors.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.bold: tabBar.currentIndex === 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: tabBar.currentIndex === 0 ? Colors.bg2 : "transparent"
                    radius: Theme.radiusSmall
                    border.color: tabBar.currentIndex === 0 ? Colors.borderHi : "transparent"
                }
            }

            TabButton {
                text: "UDP"
                implicitWidth: 110
                contentItem: Text {
                    text: parent.text
                    color: tabBar.currentIndex === 1 ? Colors.accent : Colors.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.bold: tabBar.currentIndex === 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: tabBar.currentIndex === 1 ? Colors.bg2 : "transparent"
                    radius: Theme.radiusSmall
                    border.color: tabBar.currentIndex === 1 ? Colors.borderHi : "transparent"
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingM
            Layout.rightMargin: Theme.spacingM
            currentIndex: tabBar.currentIndex

            // ── SERIAL tab ────────────────────────────────────────────────
            ColumnLayout {
                spacing: Theme.spacingS

                Text {
                    text: "PORT"
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: Theme.fontFamily
                    font.letterSpacing: 1
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    ComboBox {
                        id: portCombo
                        Layout.fillWidth: true
                        implicitHeight: 30
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily

                        textRole: "display"
                        valueRole: "port"

                        contentItem: Text {
                            leftPadding: 8
                            text: portCombo.displayText || "No ports found"
                            color: Colors.textPrimary
                            font: portCombo.font
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            color: Colors.bg0
                            border.color: Colors.border
                            radius: Theme.radiusSmall
                        }

                        delegate: ItemDelegate {
                            width: portCombo.width
                            contentItem: Column {
                                Text {
                                    text: modelData.display || modelData.port || ""
                                    color: Colors.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: (modelData.description || "") +
                                          (modelData.manufacturer ? "  ·  " + modelData.manufacturer : "")
                                    color: Colors.textSecondary
                                    font.pixelSize: Theme.fontSizeTiny
                                    font.family: Theme.fontFamily
                                    elide: Text.ElideRight
                                    width: portCombo.width - 24
                                }
                            }
                            highlighted: portCombo.highlightedIndex === index
                        }
                    }

                    IGButton {
                        text: "⟳"
                        implicitWidth: 32
                        implicitHeight: 30
                        onClicked: refreshPorts()
                    }
                }

                Text {
                    text: "BAUD RATE"
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: Theme.fontFamily
                    font.letterSpacing: 1
                    Layout.topMargin: Theme.spacingS
                }

                ComboBox {
                    id: baudCombo
                    Layout.fillWidth: true
                    implicitHeight: 30
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily

                    model: ConnectionManager ? ConnectionManager.supportedBaudRates() : []
                    Component.onCompleted: {
                        const idx = find(AppSettings ? String(AppSettings.serialBaud) : "115200")
                        currentIndex = idx >= 0 ? idx : 1
                    }

                    contentItem: Text {
                        leftPadding: 8
                        text: baudCombo.displayText
                        color: Colors.textPrimary
                        font: baudCombo.font
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: Colors.bg0
                        border.color: Colors.border
                        radius: Theme.radiusSmall
                    }

                    delegate: ItemDelegate {
                        width: baudCombo.width
                        contentItem: Text {
                            text: modelData
                            color: Colors.textPrimary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                        }
                        highlighted: baudCombo.highlightedIndex === index
                    }
                }

                Text {
                    Layout.topMargin: Theme.spacingS
                    text: "Tip: ESP32 MAVLink bridges commonly run at 115200."
                    color: Colors.textDisabled
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: Theme.fontFamily
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ── UDP tab ───────────────────────────────────────────────────
            ColumnLayout {
                spacing: Theme.spacingS

                Text {
                    text: "HOST / IP"
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: Theme.fontFamily
                    font.letterSpacing: 1
                }

                TextField {
                    id: udpHost
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: AppSettings ? AppSettings.udpHost : "0.0.0.0"
                    color: Colors.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    selectByMouse: true

                    background: Rectangle {
                        color: Colors.bg0
                        border.color: udpHost.activeFocus ? Colors.borderActive : Colors.border
                        radius: Theme.radiusSmall
                    }
                }

                Text {
                    text: "PORT"
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: Theme.fontFamily
                    font.letterSpacing: 1
                    Layout.topMargin: Theme.spacingS
                }

                TextField {
                    id: udpPort
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: AppSettings ? String(AppSettings.udpPort) : "14550"
                    color: Colors.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    selectByMouse: true
                    validator: IntValidator { bottom: 1; top: 65535 }

                    background: Rectangle {
                        color: Colors.bg0
                        border.color: udpPort.activeFocus ? Colors.borderActive : Colors.border
                        radius: Theme.radiusSmall
                    }
                }

                Text {
                    Layout.topMargin: Theme.spacingS
                    text: "Bind 0.0.0.0 to listen for telemetry on any interface. " +
                          "Port 14550 is the MAVLink default."
                    color: Colors.textDisabled
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: Theme.fontFamily
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // ── Status line ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingM
            implicitHeight: 30
            color: Colors.bg0

            Text {
                id: statusText
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: "Select a transport and connect"
                color: Colors.textSecondary
                font.pixelSize: Theme.fontSizeTiny
                font.family: Theme.fontFamily
            }
        }

        // ── Actions ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingM
            spacing: Theme.spacingS

            IGButton {
                text: "DISCONNECT"
                enabled: root.linkUp
                onClicked: ConnectionManager.disconnect()
            }

            Item { Layout.fillWidth: true }

            IGButton {
                text: "CLOSE"
                onClicked: root.close()
            }

            IGButton {
                text: root.linkUp ? "RECONNECT" : "CONNECT"
                active: true
                onClicked: {
                    if (root.linkUp)
                        ConnectionManager.disconnect()
                    root.attemptConnect()
                }
            }
        }
    }

    // Reflect live link state while the dialog is open.
    Connections {
        target: ConnectionManager
        function onConnectionStateChanged(state) {
            statusText.text = ConnectionManager.description
        }
        function onErrorOccurred(message) {
            statusText.text = "⚠ " + message
        }
    }
}