import QtQuick 2.15
import "../theme"

/*
 * Vertical altitude tape.
 *
 * Slides a ladder of altitude ticks past a fixed centre marker, so the
 * current altitude is always on the centre line. Values come straight from
 * vehicle telemetry — nothing here is animated or invented.
 */
Item {
    id: root

    property real altitude:    0      // metres, relative
    property real climbRate:   0      // m/s
    property string reference: "REL"  // "REL" | "MSL"

    readonly property int  pxPerMetre: 4
    readonly property int  majorStep:  10   // labelled every 10 m
    readonly property int  minorStep:  5
    readonly property int  topBarH:    16   // reference label strip
    readonly property int  botBarH:    18   // climb-rate strip

    // Usable drawing height between the two fixed bars.
    readonly property real ladderH: height - topBarH - botBarH
    // Where the current altitude sits inside the tape, in metres.
    readonly property real windowMetres: ladderH / pxPerMetre

    Rectangle {
        anchors.fill: parent
        color: Colors.bg0
        border.color: Colors.border
        border.width: 1
        radius: Theme.radiusSmall
        clip: true

        // ── Moving ladder ────────────────────────────────────────────────
        // Ticks are positioned relative to the centre line by (tickAlt - altitude).
        // The ladder is clipped to the band between the reference label and the
        // climb-rate strip so ticks never overdraw those bars.
        Item {
            id: ladder
            anchors {
                top: parent.top;    topMargin: root.topBarH
                bottom: parent.bottom; bottomMargin: root.botBarH
                left: parent.left;  right: parent.right
            }
            clip: true

            Repeater {
                model: {
                    // Cover the visible window with a margin either side.
                    const half = root.windowMetres / 2 + root.majorStep
                    const lo = Math.floor((root.altitude - half) / root.minorStep) * root.minorStep
                    const hi = Math.ceil((root.altitude + half) / root.minorStep) * root.minorStep
                    const out = []
                    for (let a = lo; a <= hi; a += root.minorStep)
                        out.push(a)
                    return out
                }

                delegate: Item {
                    width: ladder.width
                    height: 1

                    // modelData is the tick's altitude in metres.
                    readonly property real tickAlt: modelData
                    readonly property bool isMajor: (Math.abs(tickAlt) % root.majorStep) < 0.001

                    // Distance from centre line, in pixels. Positive = below centre.
                    readonly property real dy: (tickAlt - root.altitude) * root.pxPerMetre

                    // The centre marker prints the live value, so suppress the
                    // ladder tick within one label height of it to avoid the
                    // stray "0" that used to overlap the readout.
                    readonly property bool atCentre: Math.abs(dy) < 11

                    y: ladder.height / 2 + dy - height
                    visible: Math.abs(dy) < ladder.height / 2 + 20 && !atCentre

                    // Tick mark
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: isMajor ? 0 : parent.width * 0.55
                        width: isMajor ? parent.width * 0.55 : parent.width * 0.45
                        height: 1
                        color: isMajor ? Colors.textSecondary : Colors.textDisabled
                    }

                    // Label
                    Text {
                        visible: isMajor
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        text: Math.round(tickAlt)
                        color: Colors.textSecondary
                        font.pixelSize: Theme.fontSizeTiny
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        // ── Centre marker + current value ────────────────────────────────
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: 22
            color: Qt.rgba(1, 0.6, 0.2, 0.18)
            border.color: Colors.accent
            border.width: 1
            z: 2

            Text {
                anchors.centerIn: parent
                text: root.altitude.toFixed(0)
                color: Colors.textBright
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.bold: true
            }
        }

        // Pointer triangles on the centre line
        Canvas {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 10
            z: 3
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = Colors.accent
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(width, height / 2)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
            }
        }

        // ── Reference label ──────────────────────────────────────────────
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: root.topBarH
            color: Colors.bg2
            z: 4

            Text {
                anchors.centerIn: parent
                text: root.reference
                color: Colors.accent
                font.pixelSize: Theme.fontSizeTiny
                font.family: Theme.fontFamily
                font.bold: true
                font.letterSpacing: 1
            }
        }

        // ── Climb-rate indicator (bottom) ────────────────────────────────
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: root.botBarH
            color: Colors.bg2
            z: 4

            Text {
                anchors.centerIn: parent
                // Vertical speed: arrow + magnitude, sign-aware.
                text: (root.climbRate >= 0 ? "▲ " : "▼ ") + Math.abs(root.climbRate).toFixed(1)
                color: root.climbRate >= 0 ? Colors.ok : Colors.warning
                font.pixelSize: Theme.fontSizeTiny
                font.family: Theme.fontFamily
                font.bold: true
            }
        }
    }
}