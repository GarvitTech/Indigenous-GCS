import QtQuick 2.15
import "../theme"

Item {
    id: root
    width: 120; height: 60
    property real rollDeg: 0

    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0,0,width,height)
            const cx=width/2, cy=height-4, r=height-8
            ctx.strokeStyle=Colors.border; ctx.lineWidth=2
            ctx.beginPath(); ctx.arc(cx,cy,r,Math.PI,0); ctx.stroke()

            // Roll pointer
            const a = (Math.PI + root.rollDeg*Math.PI/180)
            ctx.strokeStyle=Colors.accent; ctx.lineWidth=3
            ctx.beginPath()
            ctx.moveTo(cx+r*Math.cos(a), cy+r*Math.sin(a))
            ctx.lineTo(cx+(r-12)*Math.cos(a), cy+(r-12)*Math.sin(a))
            ctx.stroke()

            ctx.fillStyle=Colors.textPrimary; ctx.font="11px monospace"; ctx.textAlign="center"
            ctx.fillText(root.rollDeg.toFixed(1)+"°", cx, cy-4)
        }
        onWidthChanged: requestPaint()
        Connections {
            target: root
            function onRollDegChanged() { parent.requestPaint() }
        }
    }
}
