import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property var sessions: LogReader.listSessions()

    // Refresh sessions list whenever logging stops/starts
    Connections {
        target: FlightLogger
        function onLoggingChanged() {
            if (!FlightLogger.logging) {
                root.sessions = LogReader.listSessions()
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        // ── HEADER ────────────────────────────────────────────────────────
        RowLayout {
            spacing: Theme.spacingS
            Layout.fillWidth: true

            Text {
                text: "FLIGHT LOGS"
                color: Colors.accent
                font.pixelSize: Theme.fontSizeMedium
                font.family: Theme.fontFamily
                font.bold: true
                font.letterSpacing: 2
            }

            Item { Layout.fillWidth: true }

            // Animated recording dot
            Rectangle {
                width: 10; height: 10; radius: 5
                color: FlightLogger.logging ? Colors.critical : Colors.textDisabled
                SequentialAnimation on opacity {
                    running: FlightLogger.logging
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            Text {
                text: FlightLogger.logging ? "● RECORDING" : "○ STOPPED"
                color: FlightLogger.logging ? Colors.critical : Colors.textDisabled
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.bold: true
            }

            Rectangle { width: 1; height: 20; color: Colors.border }

            IGButton {
                text: "START LOGGING"
                implicitWidth: 120
                baseColor: Colors.ok
                textColor: Colors.bg0
                visible: !FlightLogger.logging
                onClicked: FlightLogger.startLog()
            }

            IGButton {
                text: "STOP LOGGING"
                implicitWidth: 120
                danger: true
                visible: FlightLogger.logging
                onClicked: FlightLogger.stopLog()
            }

            Rectangle { width: 1; height: 20; color: Colors.border }

            IGButton {
                text: "CLEAR ALL"
                implicitWidth: 90
                danger: true
                enabled: !FlightLogger.logging && sessions.length > 0
                onClicked: clearLogsDialog.open()
            }

            IGButton {
                text: "REFRESH"
                implicitWidth: 80
                secondary: true
                onClicked: root.sessions = LogReader.listSessions()
            }
        }

        // Session count info
        Text {
            text: sessions.length + " session(s) saved"
            color: Colors.textSecondary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }

        // ── MAIN AREA ─────────────────────────────────────────────────────
        RowLayout {
            spacing: Theme.spacingM
            Layout.fillWidth: true
            Layout.fillHeight: true

            // LEFT: Session list
            Rectangle {
                Layout.preferredWidth: 310
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
                        radius: Theme.radiusMedium
                        // Only round top corners
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: parent.height / 2
                            color: parent.color
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                            Text {
                                text: "LOG SESSIONS"
                                color: Colors.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.letterSpacing: 1
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: sessions.length.toString()
                                color: Colors.accent
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }
                    }

                    // Column headers
                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        color: Colors.bg1

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                            spacing: 0
                            Text { text: "DATE / LABEL";    color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 140 }
                            Text { text: "VEH ID";          color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 55 }
                            Text { text: "ENTRIES";         color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 55 }
                            Text { text: "EXPORT";          color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        }
                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: sessions.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "No log sessions yet.\nStart logging to record flight data."
                            color: Colors.textDisabled
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    ListView {
                        id: sessionList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        visible: sessions.length > 0
                        model: root.sessions

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            id: sessRow
                            width: sessionList.width
                            height: 52
                            color: sessionList.currentIndex === index
                                   ? Colors.accentGlow
                                   : (sessHov.containsMouse ? Colors.bg3 : "transparent")
                            border.color: sessionList.currentIndex === index ? Colors.accent : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                                spacing: 4

                                // Date + label
                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 140
                                    Text {
                                        text: modelData.label || ("#" + modelData.id)
                                        color: Colors.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.family: Theme.fontFamily
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.started || "—"
                                        color: Colors.textSecondary
                                        font.pixelSize: Theme.fontSizeTiny
                                        font.family: Theme.fontFamily
                                    }
                                }

                                // Vehicle ID
                                Text {
                                    text: modelData.vehicleId !== undefined ? modelData.vehicleId.toString() : "—"
                                    color: Colors.accent
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                    Layout.preferredWidth: 45
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                // Entry count
                                Text {
                                    text: modelData.entryCount !== undefined ? modelData.entryCount.toString() : "—"
                                    color: Colors.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.fontFamily
                                    Layout.preferredWidth: 45
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                // Export button
                                IGButton {
                                    text: "EXPORT"
                                    implicitWidth: 60
                                    implicitHeight: 22
                                    secondary: true
                                    onClicked: {
                                        if (LogReader.exportSession) {
                                            LogReader.exportSession(modelData.id)
                                        }
                                    }
                                }
                            }

                            HoverHandler { id: sessHov }
                            TapHandler {
                                onTapped: {
                                    sessionList.currentIndex = index
                                    loadSession(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // RIGHT: Log data view
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
                                text: "LOG DATA"
                                color: Colors.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.letterSpacing: 1
                            }
                            Text {
                                text: "— " + logData.count + " records"
                                color: Colors.accent
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Column headers
                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        color: Colors.bg1

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                            spacing: 0
                            Text { text: "TIMESTAMP";   color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 160 }
                            Text { text: "ALT (m)";     color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 70 }
                            Text { text: "SPD (m/s)";   color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 80 }
                            Text { text: "MODE";        color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.preferredWidth: 90 }
                            Text { text: "STATE";       color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; Layout.fillWidth: true }
                        }
                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: logData.count === 0

                        Text {
                            anchors.centerIn: parent
                            text: sessionList.currentIndex >= 0
                                  ? "No records in this session."
                                  : "Select a session from the list to view its data."
                            color: Colors.textDisabled
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        visible: logData.count > 0
                        model: logData

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 24
                            color: index % 2 === 0 ? Colors.bg2 : Colors.bg3

                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingS }
                                spacing: 0
                                Text { text: model.ts;                         color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 160 }
                                Text { text: model.altRel.toFixed(1);          color: Colors.accent;        font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 70 }
                                Text { text: model.groundSpeed.toFixed(1);     color: Colors.textPrimary;   font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 80 }
                                Text { text: model.flightMode;                 color: Colors.textPrimary;   font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 90 }
                                Text { text: model.armed ? "ARMED" : "SAFE";
                                       color: model.armed ? Colors.critical : Colors.ok
                                       font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; font.bold: true; Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel { id: logData }

    function loadSession(sessionId) {
        logData.clear()
        const rows = LogReader.readSession(sessionId)
        for (let i = 0; i < rows.length; i++) logData.append(rows[i])
    }

    // ── Dialogs ───────────────────────────────────────────────────────────
    Dialog {
        id: clearLogsDialog
        title: "Delete All Flight Logs?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No

        Text {
            text: "This permanently deletes every saved flight-log session and telemetry record.\nThis action cannot be undone."
            color: Colors.textPrimary
            wrapMode: Text.WordWrap
            width: 320
        }

        onAccepted: {
            if (LogReader.clearSessions()) {
                root.sessions = LogReader.listSessions()
                logData.clear()
                sessionList.currentIndex = -1
            } else {
                clearLogsError.open()
            }
        }
    }

    Dialog {
        id: clearLogsError
        title: "Could Not Clear Logs"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok

        Text {
            text: FlightLogger.logging
                  ? "Stop the active recording before clearing saved logs."
                  : "The log database could not be updated. Check the application log for details."
            color: Colors.textPrimary
            wrapMode: Text.WordWrap
            width: 300
        }
    }
}
