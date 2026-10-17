import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property var tel: VehicleManager && VehicleManager.activeVehicle
                      ? VehicleManager.activeVehicle.telemetry : null

    // Sensor bitmask helper: returns "OK", "FAIL", or "DISABLED"
    function sensorStatus(bitmask, bit) {
        if (bitmask === undefined || bitmask === null) return "—"
        const present  = (bitmask >> bit) & 1
        const enabled  = (bitmask >> (bit + 16)) & 1
        const healthy  = (bitmask >> (bit + 32)) & 1
        if (!present)  return "N/A"
        if (!enabled)  return "DISABLED"
        if (!healthy)  return "FAIL"
        return "OK"
    }

    function sensorColor(status) {
        if (status === "OK")       return Colors.ok
        if (status === "FAIL")     return Colors.critical
        if (status === "DISABLED") return Colors.textDisabled
        return Colors.textDisabled
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        Text {
            text: "DIAGNOSTICS"
            color: Colors.accent
            font.pixelSize: Theme.fontSizeMedium
            font.family: Theme.fontFamily
            font.bold: true
            font.letterSpacing: 2
        }

        // ── TOP ROW: 3 panels ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            // MAVLINK INSPECTOR
            Rectangle {
                Layout.fillWidth: true
                height: mavCol.implicitHeight + Theme.spacingL * 2
                color: Colors.bg2
                radius: Theme.radiusMedium
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: mavCol
                    anchors { fill: parent; margins: Theme.spacingL }
                    spacing: Theme.spacingS

                    Text {
                        text: "MAVLINK INSPECTOR"
                        color: Colors.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        font.letterSpacing: 1
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

                    // Packets/sec with live indicator
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingS
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: MAVLinkManager && MAVLinkManager.packetsPerSecond > 0
                                   ? Colors.ok : Colors.textDisabled
                            SequentialAnimation on opacity {
                                running: MAVLinkManager && MAVLinkManager.packetsPerSecond > 0
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 400 }
                                NumberAnimation { to: 1.0; duration: 400 }
                            }
                        }
                        Text { text: "Packets/sec:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        Text {
                            text: MAVLinkManager ? MAVLinkManager.packetsPerSecond.toFixed(1) + " Hz" : "0 Hz"
                            color: MAVLinkManager && MAVLinkManager.packetsPerSecond > 0 ? Colors.ok : Colors.critical
                            font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "Total received:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        Text {
                            text: MAVLinkManager ? MAVLinkManager.totalPackets !== undefined
                                                   ? MAVLinkManager.totalPackets.toString() : "—" : "—"
                            color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "Dropped packets:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        Text {
                            text: MAVLinkManager ? MAVLinkManager.droppedPackets.toFixed(0) : "0"
                            color: MAVLinkManager && MAVLinkManager.droppedPackets > 0 ? Colors.warning : Colors.ok
                            font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "Vehicles:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        Text {
                            text: VehicleManager ? VehicleManager.vehicleCount.toString() : "0"
                            color: Colors.accent; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "Connection:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        ConnectionIndicator {}
                    }
                }
            }

            // BATTERY DIAGNOSTICS
            Rectangle {
                Layout.fillWidth: true
                height: batCol.implicitHeight + Theme.spacingL * 2
                color: Colors.bg2
                radius: Theme.radiusMedium
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: batCol
                    anchors { fill: parent; margins: Theme.spacingL }
                    spacing: Theme.spacingS

                    Text {
                        text: "BATTERY DIAGNOSTICS"
                        color: Colors.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        font.letterSpacing: 1
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

                    // Visual battery bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 20
                        color: Colors.bg4
                        radius: 4

                        Rectangle {
                            width: tel && tel.batteryRemaining >= 0
                                   ? parent.width * tel.batteryRemaining / 100 : 0
                            height: parent.height
                            radius: parent.radius
                            color: tel && tel.batteryRemaining < 20 ? Colors.critical
                                 : (tel && tel.batteryRemaining < 40 ? Colors.warning : Colors.ok)
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: tel && tel.batteryRemaining >= 0
                                  ? tel.batteryRemaining + "%" : "—"
                            color: Colors.textBright
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: [
                            ["Voltage:",      tel ? tel.batteryVoltage.toFixed(2) + " V" : "—"],
                            ["Current:",      tel && tel.batteryCurrent !== undefined ? tel.batteryCurrent.toFixed(2) + " A" : "—"],
                            ["Remaining:",    tel && tel.batteryRemaining >= 0 ? tel.batteryRemaining + "%" : "—"],
                            ["Consumed:",     tel && tel.batteryConsumed !== undefined ? tel.batteryConsumed.toFixed(0) + " mAh" : "—"]
                        ]
                        delegate: RowLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData[0]; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.fillWidth: true }
                            Text { text: modelData[1]; color: Colors.textPrimary;   font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
                        }
                    }
                }
            }

            // GPS DIAGNOSTICS
            Rectangle {
                Layout.fillWidth: true
                height: gpsCol.implicitHeight + Theme.spacingL * 2
                color: Colors.bg2
                radius: Theme.radiusMedium
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: gpsCol
                    anchors { fill: parent; margins: Theme.spacingL }
                    spacing: Theme.spacingS

                    Text {
                        text: "GPS DIAGNOSTICS"
                        color: Colors.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        font.letterSpacing: 1
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

                    // GPS fix badge
                    Rectangle {
                        width: gpsFixLabel.implicitWidth + 16; height: 24
                        radius: Theme.radiusSmall
                        color: tel && tel.gpsFixType >= 3 ? "#002800" : "#280000"
                        border.color: tel && tel.gpsFixType >= 3 ? Colors.ok : Colors.critical
                        border.width: 1
                        Text {
                            id: gpsFixLabel
                            anchors.centerIn: parent
                            text: tel ? (tel.gpsFixType >= 3 ? "3D FIX" : tel.gpsFixType >= 2 ? "2D FIX" : "NO FIX") : "NO LINK"
                            color: tel && tel.gpsFixType >= 3 ? Colors.ok : Colors.critical
                            font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        }
                    }

                    Repeater {
                        model: [
                            ["Fix Type:",    tel ? "FIX-" + tel.gpsFixType : "—"],
                            ["Satellites:",  tel ? tel.gpsSatCount.toString() : "—"],
                            ["HDOP:",        tel && tel.gpsHDOP !== undefined ? tel.gpsHDOP.toFixed(2) : "—"],
                            ["Latitude:",    tel ? tel.latitude.toFixed(6)  + "°" : "—"],
                            ["Longitude:",   tel ? tel.longitude.toFixed(6) + "°" : "—"],
                            ["Alt MSL:",     tel ? tel.altitudeMSL.toFixed(1) + " m" : "—"]
                        ]
                        delegate: RowLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData[0]; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 90 }
                            Text {
                                text: modelData[1]
                                color: {
                                    if (modelData[0] === "Satellites:") {
                                        const n = parseInt(modelData[1])
                                        return n >= 6 ? Colors.ok : (n >= 3 ? Colors.warning : Colors.critical)
                                    }
                                    return Colors.textPrimary
                                }
                                font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                            }
                        }
                    }
                }
            }
        }

        // ── MIDDLE ROW: Vehicle health + Connection ───────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            // VEHICLE HEALTH (sensor bitmask)
            Rectangle {
                Layout.preferredWidth: parent.width * 0.55
                height: healthCol.implicitHeight + Theme.spacingL * 2
                color: Colors.bg2
                radius: Theme.radiusMedium
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: healthCol
                    anchors { fill: parent; margins: Theme.spacingL }
                    spacing: Theme.spacingS

                    Text {
                        text: "VEHICLE HEALTH — SENSOR STATUS"
                        color: Colors.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        font.letterSpacing: 1
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

                    GridLayout {
                        columns: 4
                        columnSpacing: Theme.spacingM
                        rowSpacing: 6

                        Repeater {
                            model: [
                                ["GYRO",       0], ["ACCEL",     1],
                                ["MAG",        2], ["ABS PRES",  3],
                                ["DIFF PRES",  4], ["GPS",       5],
                                ["OPT FLOW",   6], ["VISION POS",7],
                                ["LASER ALT",  8], ["EXT GROUND",9],
                                ["ANG RATE",  10], ["MOTOR",     11]
                            ]
                            delegate: Rectangle {
                                width: sensorName.implicitWidth + sensorStat.implicitWidth + 16
                                height: 22
                                color: Colors.bg3
                                radius: Theme.radiusSmall
                                border.color: {
                                    const s = root.sensorStatus(tel ? tel.onboardControlSensorsHealth : undefined, modelData[1])
                                    return root.sensorColor(s)
                                }
                                border.width: 1

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                    spacing: 4
                                    Text {
                                        id: sensorName
                                        text: modelData[0]
                                        color: Colors.textSecondary
                                        font.pixelSize: Theme.fontSizeTiny
                                        font.family: Theme.fontFamily
                                    }
                                    Text {
                                        id: sensorStat
                                        text: root.sensorStatus(tel ? tel.onboardControlSensorsHealth : undefined, modelData[1])
                                        color: root.sensorColor(root.sensorStatus(tel ? tel.onboardControlSensorsHealth : undefined, modelData[1]))
                                        font.pixelSize: Theme.fontSizeTiny
                                        font.family: Theme.fontFamily
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // VEHICLE DIAGNOSTICS panel
            Rectangle {
                Layout.fillWidth: true
                height: vehDiagCol.implicitHeight + Theme.spacingL * 2
                color: Colors.bg2
                radius: Theme.radiusMedium
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: vehDiagCol
                    anchors { fill: parent; margins: Theme.spacingL }
                    spacing: Theme.spacingS

                    Text {
                        text: "VEHICLE DIAGNOSTICS"
                        color: Colors.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        font.letterSpacing: 1
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

                    Repeater {
                        model: [
                            ["CPU Load:",     tel && tel.cpuLoad !== undefined ? tel.cpuLoad + " ‰"          : "—"],
                            ["Flight Mode:",  tel ? tel.flightMode                                            : "—"],
                            ["Armed:",        tel ? (tel.armed ? "ARMED" : "SAFE")                           : "—"],
                            ["Roll:",         tel ? tel.roll.toFixed(1) + "°"                                : "—"],
                            ["Pitch:",        tel ? tel.pitch.toFixed(1) + "°"                               : "—"],
                            ["Heading:",      tel ? tel.heading.toFixed(0) + "°"                             : "—"],
                            ["Climb Rate:",   tel ? tel.climbRate.toFixed(2) + " m/s"                       : "—"],
                            ["RC RSSI:",      tel && tel.rcRSSI !== undefined ? tel.rcRSSI.toString()        : "—"]
                        ]
                        delegate: RowLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData[0]; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; Layout.preferredWidth: 110 }
                            Text {
                                text: modelData[1]
                                color: {
                                    if (modelData[0] === "Armed:") return modelData[1] === "ARMED" ? Colors.critical : Colors.ok
                                    return Colors.textPrimary
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.bold: modelData[0] === "Armed:"
                            }
                        }
                    }
                }
            }
        }

        // ── STATUS TEXT LOG PANEL ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.bg2
            radius: Theme.radiusMedium
            border.color: Colors.border
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: Colors.bg3

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                        Text {
                            text: "STATUS TEXT LOG"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.letterSpacing: 1
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "last 50 messages"
                            color: Colors.textDisabled
                            font.pixelSize: Theme.fontSizeTiny
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // Status messages list
                ListView {
                    id: statusTextList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    verticalLayoutDirection: ListView.BottomToTop

                    model: MAVLinkManager && MAVLinkManager.statusMessages
                           ? MAVLinkManager.statusMessages : statusMessages

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        width: statusTextList.width
                        height: 22
                        color: index % 2 === 0 ? Colors.bg2 : Colors.bg3

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spacingS }
                            spacing: Theme.spacingS

                            // Severity colour dot
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: {
                                    const sev = model.severity !== undefined ? model.severity : 6
                                    if (sev <= 2) return Colors.critical   // EMERG/ALERT/CRIT
                                    if (sev <= 4) return Colors.warning    // ERR/WARN
                                    if (sev === 5) return Colors.info      // NOTICE
                                    return Colors.textDisabled             // INFO/DEBUG
                                }
                            }

                            Text {
                                text: model.time || "—"
                                color: Colors.textDisabled
                                font.pixelSize: Theme.fontSizeTiny
                                font.family: Theme.fontFamily
                                Layout.preferredWidth: 80
                            }

                            Text {
                                text: model.text || model.message || "—"
                                color: {
                                    const sev = model.severity !== undefined ? model.severity : 6
                                    if (sev <= 2) return Colors.critical
                                    if (sev <= 4) return Colors.warning
                                    if (sev === 5) return Colors.info
                                    return Colors.textPrimary
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // ── QUICK CONNECT ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: connRow.implicitHeight + Theme.spacingL * 2
            color: Colors.bg2
            radius: Theme.radiusMedium
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                anchors { fill: parent; margins: Theme.spacingL }
                spacing: Theme.spacingS

                Text {
                    text: "QUICK CONNECT"
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.letterSpacing: 1
                }

                RowLayout {
                    id: connRow
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    Text { text: "Serial:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    ComboBox {
                        id: serialPortInput
                        model: ConnectionManager ? ConnectionManager.availableSerialPorts() : []
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
                    Text { text: "UDP:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    Rectangle {
                        width: 80; height: 28; color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1
                        TextInput { anchors { fill: parent; margins: 6 }
                        id: udpPortInput; text: "14550"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                    }
                    IGButton { text: "CONNECT UDP"; implicitWidth: 120; implicitHeight: 28
                        onClicked: ConnectionManager.connectUDP("127.0.0.1", parseInt(udpPortInput.text)) }
                    IGButton { text: "DISCONNECT"; implicitWidth: 100; implicitHeight: 28; danger: true
                        onClicked: ConnectionManager.disconnect() }
                }
            }
        }
    }

    // Fallback empty model for status messages
    ListModel { id: statusMessages }
}
