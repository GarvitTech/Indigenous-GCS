import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

/*
 * Professional Artificial Horizon / HUD
 * Sky+Ground rotate for roll. Ladder shifts vertically for pitch.
 * Speed tape left, altitude tape right, heading tape top.
 */
Item {
    id: root
    implicitWidth:  460
    implicitHeight: 240

    // ── Telemetry inputs
    property real   rollDeg:        0
    property real   pitchDeg:       0
    property real   heading:        0
    property real   altitude:       0
    property real   groundSpeed:    0
    property real   airSpeed:       0
    property real   climbRate:      0
    property real   batteryVoltage: 0
    property real   batteryPercent: -1
    property int    gpsFix:         0
    property int    satellites:     0
    property bool   armed:          false
    property bool   dataAvailable:  false
    property string flightMode:     "NO LINK"

    readonly property real normHdg:  ((heading % 360) + 360) % 360
    readonly property real tapeW:    Math.max(44, width  * 0.105)
    readonly property real hdgH:     Math.max(22, height * 0.095)
    readonly property real botH:     Math.max(24, height * 0.115)
    // pixels per degree of pitch
    readonly property real pitchPx:  (height - hdgH - botH) / 60.0

    // Repaint triggers
    onRollDegChanged:       { world.requestPaint(); rollArc.requestPaint() }
    onPitchDegChanged:      world.requestPaint()
    onDataAvailableChanged: { world.requestPaint(); rollArc.requestPaint() }
    onNormHdgChanged:       hdgTape.requestPaint()
    onWidthChanged:         { world.requestPaint(); hdgTape.requestPaint(); rollArc.requestPaint(); spTape.requestPaint(); alTape.requestPaint() }
    onHeightChanged:        { world.requestPaint(); hdgTape.requestPaint(); rollArc.requestPaint(); spTape.requestPaint(); alTape.requestPaint() }
    onGroundSpeedChanged:   spTape.requestPaint()
    onAltitudeChanged:      alTape.requestPaint()
    onClimbRateChanged:     alTape.requestPaint()

    Rectangle {
        id: frame
        anchors.fill: parent
        color: "#000"
        border.color: Colors.border
        border.width: 1
        clip: true

        // ── Heading tape (top)
        Canvas {
            id: hdgTape
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.hdgH
            onPaint: {
                const c = getContext("2d")
                c.clearRect(0, 0, width, height)
                c.fillStyle = "#1a1a1a"
                c.fillRect(0, 0, width, height)
                const pxPerDeg = width / 60.0
                const cx = width / 2
                const hdg = root.normHdg
                c.font = Math.max(8, height * 0.44) + "px " + Theme.fontFamily
                c.textAlign = "center"
                const cardinals = {0:"N",45:"NE",90:"E",135:"SE",180:"S",225:"SW",270:"W",315:"NW"}
                const first = Math.floor((hdg - 30) / 5) * 5
                for (let a = first; a <= hdg + 30; a += 5) {
                    const d = ((a % 360) + 360) % 360
                    const x = cx + (a - hdg) * pxPerDeg
                    if (x < -10 || x > width + 10) continue
                    const isMajor = (d % 10 === 0)
                    c.strokeStyle = isMajor ? "#dddddd" : "#666"
                    c.lineWidth   = isMajor ? 1.5 : 1
                    c.beginPath()
                    c.moveTo(x, height)
                    c.lineTo(x, height - (isMajor ? height * 0.55 : height * 0.28))
                    c.stroke()
                    if (isMajor) {
                        const lbl = cardinals[d] !== undefined ? cardinals[d] : d.toString()
                        c.fillStyle = cardinals[d] !== undefined ? "#ff9933" : "#ddd"
                        c.fillText(lbl, x, height * 0.52)
                    }
                }
                // Centre pointer
                c.fillStyle = "#00e676"
                c.beginPath()
                c.moveTo(cx - 5, 0); c.lineTo(cx + 5, 0); c.lineTo(cx, 7)
                c.closePath(); c.fill()
                c.strokeStyle = Colors.border; c.lineWidth = 1
                c.beginPath(); c.moveTo(0, height-1); c.lineTo(width, height-1); c.stroke()
            }
        }

        // ── Speed tape (left)
        Canvas {
            id: spTape
            anchors { left: parent.left; top: hdgTape.bottom; bottom: bottomStrip.top }
            width: root.tapeW
            onPaint: {
                const c = getContext("2d")
                c.clearRect(0, 0, width, height)
                c.fillStyle = "rgba(20,20,20,0.88)"
                c.fillRect(0, 0, width, height)
                const spd = root.groundSpeed
                const pxPerU = height / 20.0
                const cy = height / 2
                c.font = Math.max(8, pxPerU * 0.72) + "px " + Theme.fontFamily
                c.textAlign = "right"
                for (let v = Math.floor(spd/5)*5 - 50; v <= spd + 50; v += 5) {
                    if (v < 0) continue
                    const y = cy - (v - spd) * pxPerU
                    if (y < 0 || y > height) continue
                    const major = (v % 10 === 0)
                    c.strokeStyle = major ? "#ccc" : "#666"
                    c.lineWidth   = major ? 1.5 : 1
                    c.beginPath(); c.moveTo(width, y); c.lineTo(width - (major ? width*0.55 : width*0.28), y); c.stroke()
                    if (major) { c.fillStyle = "#ddd"; c.fillText(v.toFixed(0), width - width*0.58, y + 4) }
                }
                // Value box
                const bh = 22
                c.fillStyle = "#000"; c.strokeStyle = "#aaa"; c.lineWidth = 1
                c.fillRect(1, cy - bh/2, width-2, bh); c.strokeRect(1, cy - bh/2, width-2, bh)
                c.fillStyle = "#fff"; c.font = "bold " + Math.max(9, pxPerU * 0.88) + "px " + Theme.fontFamily
                c.textAlign = "center"; c.fillText(spd.toFixed(1), width/2, cy + 5)
                c.fillStyle = "#888"; c.font = "8px " + Theme.fontFamily
                c.fillText("m/s", width/2, height - 3)
            }
        }

        // ── Altitude tape (right)
        Canvas {
            id: alTape
            anchors { right: parent.right; top: hdgTape.bottom; bottom: bottomStrip.top }
            width: root.tapeW
            onPaint: {
                const c = getContext("2d")
                c.clearRect(0, 0, width, height)
                c.fillStyle = "rgba(20,20,20,0.88)"
                c.fillRect(0, 0, width, height)
                const alt = root.altitude
                const pxPerM = height / 40.0
                const cy = height / 2
                c.font = Math.max(8, pxPerM * 0.9) + "px " + Theme.fontFamily
                c.textAlign = "left"
                for (let v = Math.floor(alt/5)*5 - 100; v <= alt + 100; v += 5) {
                    const y = cy - (v - alt) * pxPerM
                    if (y < 0 || y > height) continue
                    const major = (v % 10 === 0)
                    c.strokeStyle = major ? "#ccc" : "#666"
                    c.lineWidth   = major ? 1.5 : 1
                    c.beginPath(); c.moveTo(0, y); c.lineTo(major ? 10 : 5, y); c.stroke()
                    if (major) { c.fillStyle = "#ddd"; c.fillText(v.toFixed(0), 13, y + 4) }
                }
                // Climb bar
                const cr = Math.max(-10, Math.min(10, root.climbRate))
                const barH = cr * pxPerM * 2
                c.fillStyle = "#2ca82c"; c.globalAlpha = 0.75
                if (barH > 0) c.fillRect(width-5, cy-barH, 4, barH)
                else c.fillRect(width-5, cy, 4, -barH)
                c.globalAlpha = 1.0
                // Value box
                const bh = 22
                c.fillStyle = "#000"; c.strokeStyle = "#aaa"; c.lineWidth = 1
                c.fillRect(1, cy - bh/2, width-2, bh); c.strokeRect(1, cy - bh/2, width-2, bh)
                c.fillStyle = "#fff"; c.font = "bold " + Math.max(9, pxPerM * 1.1) + "px " + Theme.fontFamily
                c.textAlign = "center"; c.fillText(alt.toFixed(1), width/2, cy + 5)
                c.fillStyle = "#888"; c.font = "8px " + Theme.fontFamily
                c.fillText("m AGL", 3, height - 3)
            }
        }

        // ── World canvas: sky/ground/horizon/ladder (clips between tapes)
        Canvas {
            id: world
            anchors {
                left: parent.left; leftMargin: root.tapeW
                right: parent.right; rightMargin: root.tapeW
                top: hdgTape.bottom
                bottom: bottomStrip.top
            }
            onPaint: {
                const c = getContext("2d")
                c.clearRect(0, 0, width, height)
                if (!root.dataAvailable) {
                    c.fillStyle = "#1a1a1a"; c.fillRect(0, 0, width, height)
                    c.fillStyle = "#444"; c.font = "13px " + Theme.fontFamily
                    c.textAlign = "center"
                    c.fillText("NO VEHICLE LINK", width/2, height/2)
                    return
                }
                const cx = width / 2
                const cy = height / 2
                const rollRad  = root.rollDeg  * Math.PI / 180.0
                const pitchOff = root.pitchDeg * root.pitchPx
                const diag = Math.sqrt(width*width + height*height) + 20

                c.save()
                // Translate to centre, rotate for roll, shift for pitch.
                // Pitch up (positive pitchDeg) must move the horizon DOWN, so the
                // offset is applied with a positive sign in screen space (y grows
                // downward). Getting this sign wrong flips sky and ground.
                c.translate(cx, cy)
                c.rotate(-rollRad)
                c.translate(0, pitchOff)

                // Sky (above the horizon). Canvas y grows downward, so the sky
                // occupies negative y and the ground positive y.
                c.fillStyle = "#4a90d9"
                c.fillRect(-diag, -diag*2, diag*2, diag*2)
                // Ground (below the horizon)
                c.fillStyle = "#7a5c1e"
                c.fillRect(-diag, 0, diag*2, diag*2)
                // Horizon line
                c.strokeStyle = "#fff"; c.lineWidth = 2.5
                c.beginPath(); c.moveTo(-diag, 0); c.lineTo(diag, 0); c.stroke()

                // Pitch ladder
                c.font = Math.max(8, root.pitchPx * 0.85) + "px " + Theme.fontFamily
                c.textAlign = "center"; c.fillStyle = "#fff"
                const steps = [-30,-20,-15,-10,-5,5,10,15,20,30]
                for (const deg of steps) {
                    // Positive pitch ladder rungs sit above the horizon, which in
                    // canvas coordinates is negative y.
                    const y   = -deg * root.pitchPx
                    const hw  = (Math.abs(deg) % 10 === 0) ? width * 0.22 : width * 0.11
                    c.strokeStyle = "#fff"
                    c.lineWidth   = (Math.abs(deg) % 10 === 0) ? 1.5 : 1.0
                    c.beginPath(); c.moveTo(-hw, y); c.lineTo(hw, y); c.stroke()
                    if (Math.abs(deg) % 10 === 0) {
                        const lbl = Math.abs(deg).toString()
                        c.fillText(lbl, -hw - 16, y + 4)
                        c.fillText(lbl,  hw + 16, y + 4)
                    }
                }
                c.restore()

                // Fixed aircraft symbol (red, stays centred)
                c.strokeStyle = "#ff2a1f"; c.lineWidth = 2.5; c.lineCap = "round"
                // Left wing
                c.beginPath(); c.moveTo(cx-7,cy); c.lineTo(cx-26,cy); c.stroke()
                c.beginPath(); c.moveTo(cx-26,cy); c.lineTo(cx-26,cy-6); c.stroke()
                // Right wing
                c.beginPath(); c.moveTo(cx+7,cy); c.lineTo(cx+26,cy); c.stroke()
                c.beginPath(); c.moveTo(cx+26,cy); c.lineTo(cx+26,cy-6); c.stroke()
                // Fuselage dot
                c.fillStyle = "#ff2a1f"; c.beginPath(); c.arc(cx,cy,3,0,Math.PI*2); c.fill()
                // Centre guide lines
                c.strokeStyle = "rgba(255,255,255,0.35)"; c.lineWidth = 1
                c.beginPath(); c.moveTo(cx-5,cy); c.lineTo(cx-55,cy); c.stroke()
                c.beginPath(); c.moveTo(cx+5,cy); c.lineTo(cx+55,cy); c.stroke()
            }
        }

        // Roll arc overlay (on top of world canvas)
        Canvas {
            id: rollArc
            anchors {
                left: parent.left; leftMargin: root.tapeW
                right: parent.right; rightMargin: root.tapeW
                top: hdgTape.bottom
                bottom: bottomStrip.top
            }
            onPaint: {
                const c = getContext("2d")
                c.clearRect(0, 0, width, height)
                if (!root.dataAvailable) return
                const cx = width / 2
                const cy = height * 0.72
                const r  = Math.min(cx, cy) * 0.88
                const ticks = [-60,-45,-30,-20,-10,0,10,20,30,45,60]
                c.strokeStyle = "rgba(200,200,200,0.6)"; c.lineWidth = 1
                for (const deg of ticks) {
                    const rad = (deg - 90) * Math.PI / 180
                    const len = (deg % 30 === 0) ? 10 : 6
                    c.beginPath()
                    c.moveTo(cx + r*Math.cos(rad), cy + r*Math.sin(rad))
                    c.lineTo(cx + (r-len)*Math.cos(rad), cy + (r-len)*Math.sin(rad))
                    c.stroke()
                }
                // Roll pointer triangle
                const pr = (root.rollDeg - 90) * Math.PI / 180
                const px = cx + r*Math.cos(pr), py = cy + r*Math.sin(pr)
                const perp = pr + Math.PI/2
                c.fillStyle = "#fff"
                c.beginPath()
                c.moveTo(px, py)
                c.lineTo(px + Math.cos(perp)*6, py + Math.sin(perp)*6)
                c.lineTo(px - Math.cos(perp)*6, py - Math.sin(perp)*6)
                c.closePath(); c.fill()
            }
        }

        // Bottom status strip
        Rectangle {
            id: bottomStrip
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: root.botH
            color: "#111"
            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                spacing: 0
                // Mode
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.flightMode
                    color: "#4a9eff"; font.pixelSize: Math.max(8, root.botH*0.42)
                    font.family: Theme.fontFamily; font.bold: true
                }
                Item { Layout.preferredWidth: 8 }
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: root.botH*0.7
                    Layout.alignment: Qt.AlignVCenter
                    color: "#333"
                }
                Item { Layout.preferredWidth: 8 }
                // GPS
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.gpsFix >= 3 ? ("GPS3D " + root.satellites + "sat") :
                          root.gpsFix >= 2 ? ("GPS2D " + root.satellites + "sat") : "NO GPS"
                    color: root.gpsFix >= 3 ? "#00e676" : (root.gpsFix >= 2 ? "#ffab00" : "#ff1744")
                    font.pixelSize: Math.max(8, root.botH*0.38)
                    font.family: Theme.fontFamily; font.bold: true
                }
                Item { Layout.preferredWidth: 8 }
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: root.botH*0.7
                    Layout.alignment: Qt.AlignVCenter
                    color: "#333"
                }
                Item { Layout.preferredWidth: 8 }
                // Battery
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.batteryPercent >= 0
                    text: root.batteryPercent >= 0 ? (root.batteryPercent + "% " + root.batteryVoltage.toFixed(1) + "V") : ""
                    color: root.batteryPercent < 20 ? "#ff1744" : (root.batteryPercent < 40 ? "#ffab00" : "#00e676")
                    font.pixelSize: Math.max(8, root.botH*0.38)
                    font.family: Theme.fontFamily; font.bold: true
                }
                // Pushes the armed badge hard against the right edge.
                Item { Layout.fillWidth: true }
                // Armed badge (right-aligned)
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: armedT.implicitWidth + 14
                    Layout.preferredHeight: root.botH*0.75
                    radius: 3
                    color: root.armed ? "#3a0000" : "#003a00"
                    border.color: root.armed ? "#ff1744" : "#00e676"; border.width: 1
                    Text {
                        id: armedT; anchors.centerIn: parent
                        text: root.armed ? "● ARMED" : "○ SAFE"
                        color: root.armed ? "#ff1744" : "#00e676"
                        font.pixelSize: Math.max(8, root.botH*0.40)
                        font.family: Theme.fontFamily; font.bold: true
                    }
                    SequentialAnimation on border.color {
                        running: root.armed; loops: Animation.Infinite
                        ColorAnimation { to: "#ff1744"; duration: 600 }
                        ColorAnimation { to: "#660000"; duration: 600 }
                    }
                }
            }
        }
    }
}
