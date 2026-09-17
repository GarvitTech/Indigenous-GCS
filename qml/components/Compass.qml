import QtQuick 2.15
import "../theme"

Item {
    id: root
    width: 160; height: 160
    property real heading: 0

    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            const cx = width/2, cy = height/2, r = Math.min(cx,cy)-4
            ctx.clearRect(0,0,width,height)

            // Background
            ctx.fillStyle = Colors.bg2
            ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2); ctx.fill()
            ctx.strokeStyle = Colors.border; ctx.lineWidth=2
            ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2); ctx.stroke()

            // Cardinal labels
            const cardinals = ["N","NE","E","SE","S","SW","W","NW"]
            ctx.font = "bold 11px monospace"
            ctx.textAlign = "center"; ctx.textBaseline = "middle"
            for (let i=0; i<8; i++) {
                const angle = (i*45 - root.heading) * Math.PI/180
                const lr = r - 16
                const x = cx + lr*Math.sin(angle)
                const y = cy - lr*Math.cos(angle)
                ctx.fillStyle = cardinals[i]==="N" ? Colors.critical : Colors.textSecondary
                ctx.fillText(cardinals[i], x, y)
            }

            // Tick marks
            for (let deg=0; deg<360; deg+=5) {
                const a = (deg - root.heading)*Math.PI/180
                const inner = deg%10===0 ? r-22 : r-14
                ctx.strokeStyle = deg%90===0 ? Colors.accent : Colors.border
                ctx.lineWidth = deg%10===0 ? 2 : 1
                ctx.beginPath()
                ctx.moveTo(cx+(inner)*Math.sin(a), cy-(inner)*Math.cos(a))
                ctx.lineTo(cx+(r-6)*Math.sin(a),   cy-(r-6)*Math.cos(a))
                ctx.stroke()
            }

            // Heading pointer
            ctx.fillStyle = Colors.accent
            ctx.beginPath()
            ctx.moveTo(cx, cy-r+8)
            ctx.lineTo(cx-5, cy-r+20)
            ctx.lineTo(cx+5, cy-r+20)
            ctx.closePath(); ctx.fill()

            // Center heading text
            ctx.fillStyle = Colors.accent
            ctx.font = "bold 14px monospace"
            ctx.fillText(Math.round(root.heading)+"°", cx, cy)
        }
        onHeadingChanged: requestPaint()
        property real heading: root.heading
    }
}
