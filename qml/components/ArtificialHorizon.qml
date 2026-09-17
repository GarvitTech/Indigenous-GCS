import QtQuick 2.15
import "../theme"

Item {
    id: root
    width: 240; height: 240

    property real rollDeg:  0
    property real pitchDeg: 0

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            const cx = width / 2, cy = height / 2, r = Math.min(cx, cy) - 4

            ctx.clearRect(0, 0, width, height)
            ctx.save()

            // Clip to circle
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.clip()

            // Rotate for roll
            ctx.translate(cx, cy)
            ctx.rotate(-root.rollDeg * Math.PI / 180)

            // Pitch offset (pixels per degree)
            const pitchPx = root.pitchDeg * 3

            // Sky
            ctx.fillStyle = "#1a3a6e"
            ctx.fillRect(-r, -r - pitchPx, r * 2, r + pitchPx)

            // Ground
            ctx.fillStyle = "#5c3a1e"
            ctx.fillRect(-r, -pitchPx, r * 2, r + pitchPx)

            // Horizon line
            ctx.strokeStyle = "#ffffff"
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(-r, -pitchPx)
            ctx.lineTo(r, -pitchPx)
            ctx.stroke()

            // Pitch lines
            ctx.strokeStyle = "rgba(255,255,255,0.6)"
            ctx.lineWidth = 1
            ctx.font = "10px monospace"
            ctx.fillStyle = "#ffffff"
            for (let deg = -30; deg <= 30; deg += 10) {
                if (deg === 0) continue
                const y = -pitchPx - deg * 3
                const w = deg % 20 === 0 ? 40 : 20
                ctx.beginPath()
                ctx.moveTo(-w, y); ctx.lineTo(w, y)
                ctx.stroke()
                if (deg % 20 === 0) {
                    ctx.fillText(Math.abs(deg), w + 4, y + 4)
                    ctx.fillText(Math.abs(deg), -w - 20, y + 4)
                }
            }

            ctx.restore()

            // Fixed aircraft symbol
            ctx.strokeStyle = Colors.accent
            ctx.lineWidth = 3
            ctx.beginPath()
            ctx.moveTo(cx - 40, cy); ctx.lineTo(cx - 10, cy)
            ctx.moveTo(cx + 10, cy); ctx.lineTo(cx + 40, cy)
            ctx.moveTo(cx, cy - 10); ctx.lineTo(cx, cy + 10)
            ctx.stroke()

            // Border
            ctx.strokeStyle = Colors.border
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()
        }
    }

    onRollDegChanged:  canvas.requestPaint()
    onPitchDegChanged: canvas.requestPaint()
}
