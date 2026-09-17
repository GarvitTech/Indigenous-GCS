import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0
    property var tel: VehicleManager && VehicleManager.activeVehicle ? VehicleManager.activeVehicle.telemetry : null

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        Text { text: "DIAGNOSTICS"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }

        RowLayout {
            spacing: Theme.spacingM; Layout.fillWidth: true

            // MAVLink stats
            Rectangle {
                Layout.preferredWidth: 260; height: 200
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingM }
                    spacing: 8
                    Text { text: "MAVLINK STATISTICS"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    Repeater {
                        model: [
                            ["Packets/sec",   MAVLinkManager ? MAVLinkManager.packetsPerSecond.toFixed(1) : "0"],
                            ["Dropped pkts",  MAVLinkManager ? MAVLinkManager.droppedPackets.toFixed(0)   : "0"],
                            ["Vehicles",      VehicleManager ? VehicleManager.vehicleCount.toString()     : "0"]
                        ]
                        delegate: RowLayout {
                            spacing: Theme.spacingM
                            Text { text: modelData[0] + ":"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 120 }
                            Text { text: modelData[1]; color: Colors.accent; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
                        }
                    }
                }
            }

            // Vehicle diagnostics
            Rectangle {
                Layout.preferredWidth: 260; height: 200
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingM }
                    spacing: 8
                    Text { text: "VEHICLE DIAGNOSTICS"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    Repeater {
                        model: [
                            ["CPU Load",   tel ? tel.cpuLoad + " ‰"              : "—"],
                            ["GPS Fix",    tel ? tel.gpsFixType.toString()        : "—"],
                            ["Satellites", tel ? tel.gpsSatCount.toString()       : "—"],
                            ["Battery",    tel ? tel.batteryRemaining + "%"       : "—"],
                            ["Voltage",    tel ? tel.batteryVoltage.toFixed(2)+"V": "—"],
                            ["Flight Mode",tel ? tel.flightMode                   : "—"]
                        ]
                        delegate: RowLayout {
                            spacing: Theme.spacingM
                            Text { text: modelData[0] + ":"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 100 }
                            Text { text: modelData[1]; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
                        }
                    }
                }
            }

            // Connection diagnostics
            Rectangle {
                Layout.preferredWidth: 260; height: 200
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.spacingM }
                    spacing: 8
                    Text { text: "CONNECTION"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    ConnectionIndicator {}
                    Text { text: ConnectionManager ? ConnectionManager.description : "—"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
        }

        // Connection setup
        Rectangle {
            Layout.fillWidth: true; height: 120
            color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1
            ColumnLayout {
                anchors { fill: parent; margins: Theme.spacingM }
                spacing: Theme.spacingS
                Text { text: "QUICK CONNECT"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                RowLayout {
                    spacing: Theme.spacingS
                    Text { text: "Serial:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    ComboBox {
                        id: serialPortInput
                        model: ConnectionManager.availableSerialPorts()
                        textRole: "portName"
                        currentIndex: count > 0 ? 0 : -1
                        implicitWidth: 170; implicitHeight: 28
                        background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                        contentItem: Text { text: serialPortInput.displayText || "No serial port"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; leftPadding: 6; verticalAlignment: Text.AlignVCenter }
                    }
                    ComboBox {
                        id: serialBaudInput
                        model: ["115200", "230400", "460800", "921600"]
                        currentIndex: 0
                        implicitWidth: 100; implicitHeight: 28
                        background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                        contentItem: Text { text: serialBaudInput.displayText; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; leftPadding: 6; verticalAlignment: Text.AlignVCenter }
                    }
                    IGButton { text: "CONNECT SERIAL"; implicitWidth: 130; implicitHeight: 28; enabled: serialPortInput.currentText !== ""; onClicked: ConnectionManager.connectSerial(serialPortInput.currentText, parseInt(serialBaudInput.currentText)) }
                    Text { text: "UDP Port:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    Rectangle {
                        width: 80; height: 28; color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1
                        TextInput { anchors { fill: parent; margins: 6 }
                        id: udpPortInput; text: "14550"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    }
                    IGButton { text: "CONNECT UDP"; implicitWidth: 130; implicitHeight: 28
                        onClicked: ConnectionManager.connectUDP("127.0.0.1", parseInt(udpPortInput.text)) }
                    IGButton { text: "DISCONNECT"; implicitWidth: 110; implicitHeight: 28; danger: true
                        onClicked: ConnectionManager.disconnect() }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
