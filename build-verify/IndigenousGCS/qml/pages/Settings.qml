import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import "../theme"

Rectangle {
    color: Colors.bg0

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingL }
        spacing: Theme.spacingM

        Text { text: "APPLICATION SETTINGS"; color: Colors.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMedium; font.bold: true; font.letterSpacing: 2 }
        Text { text: "Control display, safety prompts, and connection defaults. Changes are saved automatically."; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM
            Rectangle {
                Layout.preferredWidth: 360; Layout.preferredHeight: 220
                color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingS
                    Text { text: "DISPLAY"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.bold: true; font.letterSpacing: 1 }
                    CheckBox { text: "Light blue theme"; checked: Colors.lightTheme; onToggled: { Colors.lightTheme = checked; AppSettings.lightTheme = checked } }
                    Text { text: "The light theme uses operational light-blue surfaces and dark text for readability."; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Item { Layout.fillHeight: true }
                }
            }
            Rectangle {
                Layout.preferredWidth: 360; Layout.preferredHeight: 220
                color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingS
                    Text { text: "SAFETY"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.bold: true; font.letterSpacing: 1 }
                    CheckBox { text: "Confirm ARM / DISARM"; checked: AppSettings.confirmArm; onToggled: AppSettings.confirmArm = checked }
                    CheckBox { text: "Confirm mission upload"; checked: AppSettings.confirmMission; onToggled: AppSettings.confirmMission = checked }
                    CheckBox { text: "Auto-connect on startup"; checked: AppSettings.autoConnect; onToggled: AppSettings.autoConnect = checked }
                    Text { text: "Auto-connect is disabled by default and never runs without an explicitly saved serial port."; color: Colors.warning; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 180
            color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingS
                Text { text: "CONNECTION DEFAULTS"; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.bold: true; font.letterSpacing: 1 }
                RowLayout {
                    Text { text: "Serial port"; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 110 }
                    TextField { text: AppSettings.serialPort; placeholderText: "No saved port"; onEditingFinished: AppSettings.serialPort = text; Layout.preferredWidth: 220 }
                    Text { text: "Baud"; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                    SpinBox { from: 9600; to: 2000000; stepSize: 100; value: AppSettings.serialBaud; editable: true; onValueModified: AppSettings.serialBaud = value }
                }
                RowLayout {
                    Text { text: "UDP host"; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.preferredWidth: 110 }
                    TextField { text: AppSettings.udpHost; onEditingFinished: AppSettings.udpHost = text; Layout.preferredWidth: 220 }
                    Text { text: "UDP port"; color: Colors.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
                    SpinBox { from: 1; to: 65535; value: AppSettings.udpPort; editable: true; onValueModified: AppSettings.udpPort = value }
                }
                Text { text: "UDP listening means the local socket is open; it does not prove a flight controller is connected. The app reports FC DETECTED only after a heartbeat."; color: Colors.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
        }

        // ── HELP & DOCUMENTATION ──────────────────────────────────────────
        Rectangle {
            id: helpCard
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall

            // Result of the last guide-open attempt, shown inline rather than in
            // a transient dialog so the reason stays visible.
            property string notice: ""
            property bool   noticeIsError: false

            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingS

                Text {
                    text: "HELP & DOCUMENTATION"
                    color: Colors.textSecondary; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall; font.bold: true; font.letterSpacing: 1
                }

                Text {
                    text: "The complete user guide covers connecting to the ESP32, every page in the "
                          + "application, the safety rules, and copy-paste install commands for macOS and Windows."
                    color: Colors.textSecondary; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Theme.spacingS

                    IGButton {
                        text: "OPEN USER GUIDE"
                        implicitWidth: 170
                        active: true
                        onClicked: {
                            const ok = AppSettings.openGuide()
                            helpCard.noticeIsError = !ok
                            helpCard.notice = ok
                                ? "Guide opened in your default web browser."
                                : "Could not open the guide — no web browser was available."
                        }
                    }

                    IGButton {
                        text: "SHOW FILE PATH"
                        implicitWidth: 150
                        secondary: true
                        onClicked: {
                            const p = AppSettings.guideFilePath()
                            helpCard.noticeIsError = (p === "")
                            helpCard.notice = (p === "")
                                ? "Guide resource is missing from this build."
                                : "Guide extracted to: " + p
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    text: helpCard.notice
                    visible: helpCard.notice !== ""
                    color: helpCard.noticeIsError ? Colors.critical : Colors.ok
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // ── ABOUT ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            color: Colors.bg2; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall

            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "INDIGENOUS GCS  v1.0.0"
                        color: Colors.accent; font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeNormal; font.bold: true; font.letterSpacing: 1.5
                    }
                    Text {
                        text: "Cross-platform Ground Control Station for Indigenous ESP32 Flight Controllers"
                        color: Colors.textSecondary; font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "MADE WITH DEDICATION BY GARVIT PANT"
                    color: Colors.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.letterSpacing: 1.5
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
