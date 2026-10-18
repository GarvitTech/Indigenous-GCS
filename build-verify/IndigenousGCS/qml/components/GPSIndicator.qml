import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    spacing: 6
    property var telemetry: null

    property int fix:  telemetry ? telemetry.gpsFixType  : 0
    property int sats: telemetry ? telemetry.gpsSatCount : 0

    property color fixColor: fix >= 3 ? Colors.ok : fix >= 2 ? Colors.warning : Colors.critical
    property string fixLabel: {
        switch(fix) {
        case 0: return "NO GPS"
        case 1: return "NO FIX"
        case 2: return "2D"
        case 3: return "3D"
        case 4: return "DGPS"
        case 5: return "RTK-F"
        case 6: return "RTK"
        default: return "FIX " + fix
        }
    }

    Text { text: "GPS:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
    Text { text: fixLabel; color: fixColor; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true }
    Text { text: sats + " sat"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
}
