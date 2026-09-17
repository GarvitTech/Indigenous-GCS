import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property int selectedTab: 0
    property string lastResponse: "No MSP response received"
    property int responseCommand: -1
    property var serialPorts: []
    property int rollP: 40
    property int rollI: 30
    property int rollD: 23
    property int pitchP: 40
    property int pitchI: 30
    property int pitchD: 23
    property int yawP: 40
    property int yawI: 30
    property int yawD: 0

    function refreshPorts() {
        serialPorts = ConnectionManager.availableSerialPorts()
    }

    Component.onCompleted: refreshPorts()

    Connections {
        target: MSPManager
        function onResponseReceived(command, payload) {
            root.responseCommand = command
            root.lastResponse = "MSP " + command + " response  |  " + payload.length + " bytes  |  " + payload.toHex(" ")
        }
        function onRequestTimedOut(command) {
            root.lastResponse = "MSP " + command + " timed out"
        }
        function onProtocolError(message) {
            root.lastResponse = message
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 46
            color: Colors.bg1
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Colors.border }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                spacing: Theme.spacingS
                Text { text: "INAV CONFIGURATOR"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
                Text { text: "MSP v1"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                Item { Layout.fillWidth: true }
                ComboBox {
                    id: portCombo
                    model: root.serialPorts
                    currentIndex: count > 0 ? 0 : -1
                    implicitWidth: 150
                    implicitHeight: 28
                    textRole: "portName"
                    enabled: !ConnectionManager.isConnected
                    background: Rectangle { color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall }
                    contentItem: Text { text: portCombo.displayText || "Select serial port"; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; leftPadding: 8; verticalAlignment: Text.AlignVCenter }
                }
                ComboBox {
                    id: baudCombo
                    model: ["115200", "230400", "460800", "921600"]
                    currentIndex: 3
                    implicitWidth: 92
                    implicitHeight: 28
                    enabled: !ConnectionManager.isConnected
                    background: Rectangle { color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall }
                    contentItem: Text { text: baudCombo.displayText; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; leftPadding: 8; verticalAlignment: Text.AlignVCenter }
                }
                IGButton { text: "REFRESH"; implicitWidth: 72; implicitHeight: 28; enabled: !ConnectionManager.isConnected; onClicked: root.refreshPorts() }
                IGButton { text: ConnectionManager.isConnected ? "DISCONNECT" : "CONNECT"; implicitWidth: 94; implicitHeight: 28; danger: ConnectionManager.isConnected; enabled: ConnectionManager.isConnected || portCombo.currentText !== ""; onClicked: ConnectionManager.isConnected ? ConnectionManager.disconnect() : ConnectionManager.connectSerial(portCombo.currentText, parseInt(baudCombo.currentText)) }
                Text { text: MSPManager.waiting ? "WAITING FOR FC" : root.lastResponse; color: MSPManager.waiting ? Colors.warning : Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; elide: Text.ElideRight; Layout.maximumWidth: 520 }
            }
        }

        TabBar {
            id: tabs
            Layout.fillWidth: true
            currentIndex: root.selectedTab
            onCurrentIndexChanged: root.selectedTab = currentIndex
            background: Rectangle { color: Colors.bg2 }
            Repeater {
                model: ["SETUP", "CONFIGURATION", "PID TUNING", "RECEIVER", "MODES", "MOTORS", "OSD", "CLI"]
                TabButton {
                    id: tabButton
                    text: modelData
                    width: Math.max(100, implicitWidth + 24)
                    onClicked: root.selectedTab = index
                    contentItem: Text { text: tabButton.text; color: tabButton.checked ? Colors.accent : Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; font.bold: tabButton.checked; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: tabButton.checked ? Colors.accentGlow : "transparent"; border.color: tabButton.checked ? Colors.accent : Colors.border; border.width: tabButton.checked ? 1 : 0 }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 58
            color: Colors.bg1
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Colors.border }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                spacing: Theme.spacingL
                Text { text: "FC " + (MSPManager.fcVariant || "--") + " " + (MSPManager.fcVersion || ""); color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
                Text { text: "BOARD " + (MSPManager.boardIdentifier || "--"); color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                Text { text: "ATT " + MSPManager.roll + " / " + MSPManager.pitch + " / " + MSPManager.yaw; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                Text { text: "ALT " + MSPManager.altitude + " cm"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                Text { text: "VBAT " + MSPManager.batteryVoltage + "  " + MSPManager.batteryRemaining + "%"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                Item { Layout.fillWidth: true }
                Text { text: MSPManager.armingFlags ? "ARMED" : "DISARMED"; color: MSPManager.armingFlags ? Colors.critical : Colors.ok; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            InavPanel {
                title: "SETUP"
                subtitle: "Identify the flight controller and read its live status before changing configuration."
                commands: [
                    ["API VERSION", 1], ["FC VARIANT", 2], ["FC VERSION", 3],
                    ["BOARD INFO", 4], ["BUILD INFO", 5], ["STATUS", 101], ["ATTITUDE", 108], ["ALTITUDE", 109]
                ]
            }
            InavPanel { title: "CONFIGURATION"; subtitle: "Read configuration data from the connected INAV flight controller."; commands: [["STATUS", 101], ["ANALOG", 110], ["ARMING CONFIG", 61], ["BOX NAMES", 116]] }
            PidPanel {}
            ReceiverPanel {}
            ModesPanel {}
            OutputsPanel {}
            InavPanel { title: "OSD"; subtitle: "OSD configuration is not exposed by the current MSP v1 service yet."; commands: [] }
            InavPanel { title: "CLI"; subtitle: "CLI transport requires an interactive MSP serial session and is not enabled yet."; commands: [] }
        }
    }

    component InavPanel: ColumnLayout {
        property string title
        property string subtitle
        property var commands
        spacing: Theme.spacingM
        anchors.margins: Theme.spacingL

        RowLayout {
            Layout.fillWidth: true
            Text { text: title; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            Text { text: "FC LINK: " + (ConnectionManager.isConnected ? "CONNECTED" : "DISCONNECTED"); color: ConnectionManager.isConnected ? Colors.ok : Colors.warning; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
        }
        Text { text: subtitle; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacingS
            Repeater {
                model: commands
                IGButton {
                    text: modelData[0]
                    implicitWidth: 138
                    enabled: ConnectionManager.isConnected && !MSPManager.waiting
                    onClicked: MSPManager.request(modelData[1])
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.bg1
            border.color: Colors.border
            Text {
                anchors { fill: parent; margins: Theme.spacingM }
                text: root.lastResponse
                color: Colors.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WrapAnywhere
                verticalAlignment: Text.AlignTop
            }
        }
    }

    component PidPanel: ColumnLayout {
        spacing: Theme.spacingM
        anchors.margins: Theme.spacingL

        RowLayout {
            Layout.fillWidth: true
            Text { text: "PID TUNING"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            IGButton { text: "READ PID"; implicitWidth: 90; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.request(112) }
            IGButton { text: "SAVE TO FC"; implicitWidth: 100; enabled: ConnectionManager.isConnected && !MSPManager.waiting; active: true; onClicked: MSPManager.saveSettings() }
        }
        Text { text: "Edit the active PID profile. Values are sent through MSP_SET_PID and saved with MSP_EEPROM_WRITE."; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }

        Rectangle {
            Layout.fillWidth: true
            height: 170
            color: Colors.bg1
            border.color: Colors.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "AXIS"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 100 }
                    Text { text: "P"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 90 }
                    Text { text: "I"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 90 }
                    Text { text: "D"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 90 }
                }
                PidRow { label: "ROLL"; p: root.rollP; i: root.rollI; d: root.rollD; onChanged: { root.rollP = p; root.rollI = i; root.rollD = d } }
                PidRow { label: "PITCH"; p: root.pitchP; i: root.pitchI; d: root.pitchD; onChanged: { root.pitchP = p; root.pitchI = i; root.pitchD = d } }
                PidRow { label: "YAW"; p: root.yawP; i: root.yawI; d: root.yawD; onChanged: { root.yawP = p; root.yawI = i; root.yawD = d } }
            }
        }
        IGButton { text: "WRITE PID PROFILE"; implicitWidth: 170; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.setPid(root.rollP, root.rollI, root.rollD, root.pitchP, root.pitchI, root.pitchD, root.yawP, root.yawI, root.yawD) }
        Item { Layout.fillHeight: true }
    }

    component ReceiverPanel: ColumnLayout {
        spacing: Theme.spacingM
        anchors.margins: Theme.spacingL
        RowLayout {
            Layout.fillWidth: true
            Text { text: "RECEIVER"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            IGButton { text: "READ CHANNELS"; implicitWidth: 120; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.request(105) }
        }
        Text { text: "Live MSP_RC channel values. Centered channels are shown in the table for calibration and signal checks."; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacingS
            Repeater {
                model: MSPManager.rcChannels
                Rectangle {
                    width: 120; height: 62; color: Colors.bg1; border.color: Colors.border
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "CH " + (index + 1); color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny }
                        Text { text: modelData; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true }
                    }
                }
            }
        }
        Text { visible: MSPManager.rcChannels.length === 0; text: "No receiver data received."; color: Colors.textDisabled; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
        Item { Layout.fillHeight: true }
    }

    component OutputsPanel: ColumnLayout {
        spacing: Theme.spacingM
        anchors.margins: Theme.spacingL
        RowLayout {
            Layout.fillWidth: true
            Text { text: "MOTORS / SERVOS"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            IGButton { text: "READ MOTORS"; implicitWidth: 105; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.request(104) }
            IGButton { text: "READ SERVOS"; implicitWidth: 105; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.request(103) }
        }
        Text { text: "Telemetry only. Motor commands are intentionally disabled until disarm, throttle, and physical-propeller interlocks are verified."; color: Colors.warning; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "MOTORS"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 80 }
            Repeater {
                model: MSPManager.motorOutputs
                Rectangle { width: 86; height: 48; color: Colors.bg1; border.color: Colors.border; Text { anchors.centerIn: parent; text: modelData; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall } }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "SERVOS"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 80 }
            Repeater {
                model: MSPManager.servoOutputs
                Rectangle { width: 86; height: 48; color: Colors.bg1; border.color: Colors.border; Text { anchors.centerIn: parent; text: modelData; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall } }
            }
        }
        Item { Layout.fillHeight: true }
    }

    component ModesPanel: ColumnLayout {
        spacing: Theme.spacingM
        anchors.margins: Theme.spacingL
        RowLayout {
            Layout.fillWidth: true
            Text { text: "MODES"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            IGButton { text: "READ MODE NAMES"; implicitWidth: 135; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.request(116) }
            IGButton { text: "READ MODE IDS"; implicitWidth: 120; enabled: ConnectionManager.isConnected && !MSPManager.waiting; onClicked: MSPManager.request(119) }
        }
        Text { text: "Mode names and identifiers are read from the connected INAV controller. Range editing is held until the controller profile is known."; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: MSPManager.modeNames
            delegate: Rectangle {
                width: ListView.view.width; height: 34; color: index % 2 ? Colors.bg2 : Colors.bg1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.spacingM; anchors.rightMargin: Theme.spacingM
                    Text { text: index + 1; color: Colors.textDisabled; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 40 }
                    Text { text: modelData; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true }
                    Text { text: MSPManager.modeIds.length > index ? "ID " + MSPManager.modeIds[index] : ""; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                }
            }
        }
    }

    component PidRow: RowLayout {
        property string label
        property int p
        property int i
        property int d
        signal changed()
        Layout.fillWidth: true
        Text { text: parent.label; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 100 }
        SpinBox { from: 0; to: 255; value: parent.p; editable: true; Layout.preferredWidth: 90; onValueModified: { parent.p = value; parent.changed() } }
        SpinBox { from: 0; to: 255; value: parent.i; editable: true; Layout.preferredWidth: 90; onValueModified: { parent.i = value; parent.changed() } }
        SpinBox { from: 0; to: 255; value: parent.d; editable: true; Layout.preferredWidth: 90; onValueModified: { parent.d = value; parent.changed() } }
    }
}
