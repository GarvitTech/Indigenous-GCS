import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        RowLayout {
            spacing: Theme.spacingS
            Text { text: "FLIGHT LOGS"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 10; height: 10; radius: 5
                color: FlightLogger.logging ? Colors.critical : Colors.textDisabled
                SequentialAnimation on opacity {
                    running: FlightLogger.logging; loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
            Text { text: FlightLogger.logging ? "RECORDING" : "STOPPED"; color: FlightLogger.logging ? Colors.critical : Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
            IGButton { text: FlightLogger.logging ? "STOP LOG" : "START LOG"; implicitWidth: 100; danger: FlightLogger.logging
                onClicked: FlightLogger.logging ? FlightLogger.stopLog() : FlightLogger.startLog() }
        }

        RowLayout {
            spacing: Theme.spacingM; Layout.fillWidth: true; Layout.fillHeight: true

            // Session list
            Rectangle {
                Layout.preferredWidth: 280; Layout.fillHeight: true
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1

                ColumnLayout {
                    anchors.fill: parent; spacing: 0
                    Rectangle {
                        Layout.fillWidth: true; height: 28; color: Colors.bg3
                        Text { anchors { left: parent.left; leftMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                            text: "SESSIONS"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        model: LogReader.listSessions()
                        delegate: Rectangle {
                            width: ListView.view.width; height: 50
                            color: sessionList.currentIndex === index ? Colors.accentGlow : (hov.containsMouse ? Colors.bg3 : "transparent")
                            border.color: sessionList.currentIndex === index ? Colors.accent : "transparent"; border.width: 1
                            ColumnLayout {
                                anchors { fill: parent; margins: Theme.spacingS }
                                spacing: 2
                                Text { text: "#" + modelData.id + " — " + modelData.label; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                Text { text: modelData.started; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily }
                            }
                            HoverHandler { id: hov }
                            TapHandler { onTapped: { sessionList.currentIndex = index; loadSession(modelData.id) } }
                        }
                        id: sessionList
                    }
                }
            }

            // Log data view
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1

                ColumnLayout {
                    anchors.fill: parent; spacing: 0
                    Rectangle {
                        Layout.fillWidth: true; height: 28; color: Colors.bg3
                        Text { anchors { left: parent.left; leftMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                            text: "LOG DATA — " + logData.count + " records"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                    }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        model: logData
                        delegate: Rectangle {
                            width: ListView.view.width; height: 24
                            color: index % 2 === 0 ? Colors.bg2 : Colors.bg3
                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingS }
                                spacing: Theme.spacingM
                                Text { text: model.ts;                    color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 160 }
                                Text { text: model.altRel.toFixed(1)+"m"; color: Colors.accent;        font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 60 }
                                Text { text: model.groundSpeed.toFixed(1)+"m/s"; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 70 }
                                Text { text: model.flightMode;            color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily; Layout.preferredWidth: 80 }
                                Text { text: model.armed ? "ARMED" : "DISARMED"; color: model.armed ? Colors.critical : Colors.ok; font.pixelSize: Theme.fontSizeSmall - 1; font.family: Theme.fontFamily }
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
}
