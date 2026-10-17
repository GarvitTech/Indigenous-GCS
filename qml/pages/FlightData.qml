import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtLocation 6.5
import QtPositioning 6.5
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property var tel: VehicleManager && VehicleManager.activeVehicle
                      ? VehicleManager.activeVehicle.telemetry : null

    // ── SIMULATION banner ──────────────────────────────────────────────────
    Rectangle {
        id: simBanner
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Simulator && Simulator.running ? 32 : 0
        visible: height > 0
        color: Colors.warning
        z: 10
        Behavior on height { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: "⚠  SIMULATION MODE — NO REAL AIRCRAFT  ⚠"
            color: Colors.bg0
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            font.bold: true
            font.letterSpacing: 2
        }
    }

    // ── Main split layout ──────────────────────────────────────────────────
    RowLayout {
        anchors {
            fill: parent
            topMargin: (Simulator && Simulator.running ? 32 : 0) + Theme.spacingM
            leftMargin: Theme.spacingM
            rightMargin: Theme.spacingM
            bottomMargin: Theme.spacingS
        }
        spacing: Theme.spacingM

        Behavior on anchors.topMargin { NumberAnimation { duration: 200 } }

        // ── LEFT PANEL (HUD column) ──────────────────────────────────────
        // Fixed-ish width rather than a percentage: the HUD and compass have
        // intrinsic sizes, and a percentage width let the compass get clipped
        // on narrower windows.
        ColumnLayout {
            Layout.preferredWidth: Math.max(380, parent.width * 0.36)
            Layout.minimumWidth: 340
            Layout.fillHeight: true
            spacing: Theme.spacingS

            Text {
                text: "FLIGHT DATA"
                color: Colors.accent
                font.pixelSize: Theme.fontSizeMedium
                font.family: Theme.fontFamily
                font.bold: true
                font.letterSpacing: 2
            }

            // HUD + AltitudeTape row. minimumHeight keeps the tapes legible
            // when the window is short instead of squeezing them to nothing.
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 230
                spacing: 4

                ArtificialHorizon {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 230

                    rollDeg:        tel ? tel.roll : 0
                    pitchDeg:       tel ? tel.pitch : 0
                    heading:        tel ? tel.heading : 0
                    altitude:       tel ? tel.altitudeRel : 0
                    groundSpeed:    tel ? tel.groundSpeed : 0
                    airSpeed:       tel ? tel.airSpeed : 0
                    climbRate:      tel ? tel.climbRate : 0
                    batteryPercent: tel ? tel.batteryRemaining : -1
                    batteryVoltage: tel ? tel.batteryVoltage : 0
                    gpsFix:         tel ? tel.gpsFixType : 0
                    satellites:     tel ? tel.gpsSatCount : 0
                    armed:          tel ? tel.armed : false
                    dataAvailable:  tel !== null
                    flightMode:     tel ? tel.flightMode : "NO LINK"
                }

                AltitudeTape {
                    Layout.preferredWidth: 92
                    Layout.minimumWidth: 84
                    Layout.fillHeight: true
                    Layout.minimumHeight: 230
                    altitude:  tel ? tel.altitudeRel : 0
                    climbRate: tel ? tel.climbRate : 0
                    reference: "REL"
                }
            }

            // Compass + attitude row. The compass is square, so it gets a
            // square slot and the attitude bar takes the rest.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                Layout.minimumHeight: 120
                spacing: Theme.spacingM

                Compass {
                    Layout.preferredWidth: 128
                    Layout.preferredHeight: 128
                    Layout.alignment: Qt.AlignVCenter
                    heading: tel ? tel.heading : 0
                }

                AttitudeIndicator {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignVCenter
                    rollDeg: tel ? tel.roll : 0
                }
            }
        }

        // ── RIGHT PANEL (60%) ────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingM

            // ── TOP: Real interactive map ────────────────────────────────
            Item {
                id: mapHost
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                Layout.minimumHeight: 200
                clip: true

                Plugin {
                    id: flightMapPlugin
                    name: "osm"
                    PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
                    PluginParameter {
                        name: "osm.mapping.custom.host"
                        value: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                    }
                    PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: "" }
                    PluginParameter { name: "osm.mapping.custom.datacopyright"; value: "" }
                    PluginParameter { name: "osm.useragent"; value: "IndigenousGCS/1.0" }
                }

                // supportedMapTypes is resolved asynchronously by the plugin, so
                // retry briefly until the CustomMap provider is available. This
                // lives on the host Item (not inside Map) so the function and its
                // caller share one unambiguous scope.
                function applyFlightMapType() {
                    var types = flightMapPlugin.supportedMapTypes
                    if (!types || types.length === 0) return false
                    for (var i = 0; i < types.length; ++i) {
                        if (types[i].style === MapType.CustomMap || types[i].style === 100) {
                            if (flightMap.activeMapType !== types[i])
                                flightMap.activeMapType = types[i]
                            return true
                        }
                    }
                    // Fallback: pick the first available type rather than leaving
                    // the token-gated default in place.
                    if (types.length > 0) {
                        if (flightMap.activeMapType !== types[0])
                            flightMap.activeMapType = types[0]
                        return true
                    }
                    return false
                }

                Timer {
                    interval: 400; repeat: true; running: true; triggeredOnStart: true
                    property int attempts: 0
                    onTriggered: {
                        if (mapHost.applyFlightMapType() || ++attempts >= 8)
                            running = false
                    }
                }

                Map {
                    id: flightMap
                    anchors.fill: parent
                    plugin: flightMapPlugin
                    center: QtPositioning.coordinate(
                        tel && tel.latitude !== 0 ? tel.latitude : 28.6139,
                        tel && tel.longitude !== 0 ? tel.longitude : 77.2090
                    )
                    zoomLevel: 15
                    copyrightsVisible: false

                    // Vehicle position marker
                    MapQuickItem {
                        id: vehicleMarker
                        coordinate: QtPositioning.coordinate(
                            tel && tel.latitude !== 0 ? tel.latitude : 28.6139,
                            tel && tel.longitude !== 0 ? tel.longitude : 77.2090
                        )
                        anchorPoint: Qt.point(16, 16)
                        visible: tel !== null
                        sourceItem: Item {
                            width: 32; height: 32
                            Rectangle {
                                anchors.centerIn: parent
                                width: 24; height: 24; radius: 12
                                color: "transparent"
                                border.color: tel && tel.armed ? Colors.critical : Colors.accent
                                border.width: 2
                                SequentialAnimation on border.color {
                                    running: tel && tel.armed; loops: Animation.Infinite
                                    ColorAnimation { to: Colors.critical; duration: 600 }
                                    ColorAnimation { to: Colors.warning; duration: 600 }
                                }
                            }
                            // Heading arrow
                            Canvas {
                                anchors.fill: parent
                                property real hdg: tel ? tel.heading : 0
                                onHdgChanged: requestPaint()
                                onPaint: {
                                    const c = getContext("2d")
                                    c.clearRect(0, 0, width, height)
                                    const cx = width/2, cy = height/2
                                    const rad = (hdg - 90) * Math.PI / 180
                                    c.strokeStyle = (tel && tel.armed) ? "#ff1744" : "#ff9933"
                                    c.lineWidth = 2.5
                                    c.beginPath()
                                    c.moveTo(cx, cy)
                                    c.lineTo(cx + Math.cos(rad) * 13, cy + Math.sin(rad) * 13)
                                    c.stroke()
                                }
                            }
                        }
                    }

                    // Follow vehicle when position updates
                    Connections {
                        target: tel
                        enabled: tel !== null
                        function onPositionChanged() {
                            if (tel && tel.latitude !== 0)
                                flightMap.center = QtPositioning.coordinate(tel.latitude, tel.longitude)
                        }
                    }

                    // Pinch to zoom
                    PinchHandler {
                        target: null
                        onActiveScaleChanged: {
                            flightMap.zoomLevel += Math.log2(activeScale)
                        }
                    }

                    // Scroll wheel zoom
                    WheelHandler {
                        target: null
                        onWheel: function(event) {
                            const delta = event.angleDelta.y
                            flightMap.zoomLevel += (delta > 0 ? 0.5 : -0.5)
                        }
                    }

                    // LIVE MAP label (top-left)
                    Rectangle {
                        anchors { top: parent.top; left: parent.left; margins: 6 }
                        color: "#cc000000"; radius: 4
                        width: mapLabel.implicitWidth + 12; height: 22
                        Text {
                            id: mapLabel
                            anchors.centerIn: parent
                            text: "LIVE MAP"
                            color: Colors.accent
                            font.pixelSize: Theme.fontSizeTiny
                            font.family: Theme.fontFamily
                            font.bold: true
                            font.letterSpacing: 2
                        }
                    }

                    // Coordinate overlay (top-right)
                    Rectangle {
                        anchors { top: parent.top; right: parent.right; margins: 6 }
                        color: "#cc000000"; radius: 4
                        width: coordLabel.implicitWidth + 10; height: 22
                        Text {
                            id: coordLabel
                            anchors.centerIn: parent
                            text: tel ? tel.latitude.toFixed(5) + "° " + tel.longitude.toFixed(5) + "°" : "—"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeTiny
                            font.family: Theme.fontFamily
                        }
                    }

                    // Zoom buttons (right-center)
                    Column {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 8 }
                        spacing: 4
                        Rectangle {
                            width: 28; height: 28; radius: 4
                            color: "#cc1a1e2a"; border.color: Colors.border; border.width: 1
                            Text { anchors.centerIn: parent; text: "+"; color: Colors.textPrimary; font.pixelSize: 18; font.bold: true }
                            TapHandler { onTapped: flightMap.zoomLevel = Math.min(19, flightMap.zoomLevel + 1) }
                        }
                        Rectangle {
                            width: 28; height: 28; radius: 4
                            color: "#cc1a1e2a"; border.color: Colors.border; border.width: 1
                            Text { anchors.centerIn: parent; text: "−"; color: Colors.textPrimary; font.pixelSize: 18; font.bold: true }
                            TapHandler { onTapped: flightMap.zoomLevel = Math.max(2, flightMap.zoomLevel - 1) }
                        }
                    }
                }
            }

            // ── BOTTOM: Telemetry cards (2-column grid) ──────────────────
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: Theme.spacingS
                rowSpacing: Theme.spacingS

                // Column A
                TelemetryCard { label: "GND SPD"; value: tel ? tel.groundSpeed.toFixed(1) : "—"; unit: "m/s"; Layout.fillWidth: true }
                TelemetryCard { label: "AIR SPD"; value: tel ? tel.airSpeed.toFixed(1)    : "—"; unit: "m/s"; Layout.fillWidth: true }
                TelemetryCard { label: "ALT REL"; value: tel ? tel.altitudeRel.toFixed(1) : "—"; unit: "m";   Layout.fillWidth: true }
                TelemetryCard { label: "CLIMB";   value: tel ? tel.climbRate.toFixed(1)   : "—"; unit: "m/s"; Layout.fillWidth: true }
                TelemetryCard { label: "GPS FIX"; value: tel ? "FIX-" + tel.gpsFixType   : "—";              Layout.fillWidth: true }
                TelemetryCard { label: "SATS";    value: tel ? tel.gpsSatCount.toString() : "—";              Layout.fillWidth: true
                    valueColor: tel && tel.gpsSatCount >= 6 ? Colors.ok : Colors.warning }
                TelemetryCard { label: "BATTERY"; value: tel ? tel.batteryRemaining + "%" : "—";              Layout.fillWidth: true
                    valueColor: tel && tel.batteryRemaining < 20 ? Colors.critical : (tel && tel.batteryRemaining < 40 ? Colors.warning : Colors.ok) }
                TelemetryCard { label: "VOLTAGE"; value: tel ? tel.batteryVoltage.toFixed(2) : "—"; unit: "V"; Layout.fillWidth: true }
                TelemetryCard { label: "RC RSSI"; value: tel && tel.rcRSSI !== undefined ? tel.rcRSSI.toString() : "—"; Layout.fillWidth: true }
                TelemetryCard { label: "CPU";     value: tel && tel.cpuLoad !== undefined ? tel.cpuLoad + "‰" : "—"; Layout.fillWidth: true }
                TelemetryCard { label: "HEADING"; value: tel ? tel.heading.toFixed(0)     : "—"; unit: "°";   Layout.fillWidth: true }
                TelemetryCard { label: "ALT MSL"; value: tel ? tel.altitudeMSL.toFixed(1) : "—"; unit: "m";   Layout.fillWidth: true }
            }
        }
    }

    // ── BOTTOM BAR ─────────────────────────────────────────────────────────
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 48
        color: Colors.bg1
        border.color: Colors.border
        border.width: 1

        RowLayout {
            anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
            spacing: Theme.spacingS

            // ARM / DISARM buttons with confirmation dialog
            IGButton {
                text: "ARM"
                implicitWidth: 80
                baseColor: Colors.warning
                textColor: Colors.bg0
                enabled: tel !== null && !(tel.armed)
                onClicked: armDialog.open()
            }

            IGButton {
                text: "DISARM"
                implicitWidth: 80
                danger: true
                enabled: tel !== null && tel.armed
                onClicked: disarmDialog.open()
            }

            Rectangle { width: 1; height: 28; color: Colors.border }

            // Flight Mode selector
            FlightModeSelector {}

            Rectangle { width: 1; height: 28; color: Colors.border }

            // Armed status
            Rectangle {
                width: armedLabel.implicitWidth + 16; height: 26
                color: tel && tel.armed ? "#500000" : "#002000"
                radius: Theme.radiusSmall
                border.color: tel && tel.armed ? Colors.critical : Colors.ok
                border.width: 1
                Text {
                    id: armedLabel
                    anchors.centerIn: parent
                    text: tel ? (tel.armed ? "● ARMED" : "○ SAFE") : "○ SAFE"
                    color: tel && tel.armed ? Colors.critical : Colors.ok
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            // Quick status: mode
            Text {
                text: tel ? tel.flightMode : "NO LINK"
                color: Colors.accent
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.bold: true
            }

            Text { text: "|"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall }

            Text {
                text: tel ? tel.altitudeRel.toFixed(1) + "m" : "—"
                color: Colors.accentBlue
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.bold: true
            }

            Text { text: "|"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeSmall }

            Text {
                text: tel ? tel.groundSpeed.toFixed(1) + "m/s" : "—"
                color: Colors.accentBlue
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.bold: true
            }
        }
    }

    // ── ARM Confirmation Dialog ────────────────────────────────────────────
    Dialog {
        id: armDialog
        title: "⚠  CONFIRM ARM"
        modal: true
        anchors.centerIn: Overlay.overlay

        background: Rectangle {
            color: Colors.bg2
            radius: Theme.radiusMedium
            border.color: Colors.warning
            border.width: 2
        }

        ColumnLayout {
            spacing: Theme.spacingM
            width: 320

            Text {
                text: "You are about to ARM the vehicle.\n\nEnsure the area is CLEAR of people and obstacles.\nPropellers WILL spin immediately upon arming."
                color: Colors.textPrimary
                font.pixelSize: Theme.fontSizeNormal
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        footer: RowLayout {
            spacing: Theme.spacingS
            Item { Layout.fillWidth: true }
            IGButton {
                text: "Cancel"
                secondary: true
                onClicked: armDialog.close()
            }
            IGButton {
                text: "ARM VEHICLE"
                baseColor: Colors.warning
                textColor: Colors.bg0
                onClicked: {
                    const v = VehicleManager ? VehicleManager.activeVehicle : null
                    if (v) v.arm()
                    armDialog.close()
                }
            }
        }
    }

    // ── DISARM Confirmation Dialog ─────────────────────────────────────────
    Dialog {
        id: disarmDialog
        title: "Confirm DISARM"
        modal: true
        anchors.centerIn: Overlay.overlay

        background: Rectangle {
            color: Colors.bg2
            radius: Theme.radiusMedium
            border.color: Colors.critical
            border.width: 2
        }

        Text {
            text: "Disarm the vehicle?"
            color: Colors.textPrimary
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
        }

        footer: RowLayout {
            spacing: Theme.spacingS
            Item { Layout.fillWidth: true }
            IGButton {
                text: "Cancel"
                secondary: true
                onClicked: disarmDialog.close()
            }
            IGButton {
                text: "DISARM"
                danger: true
                onClicked: {
                    const v = VehicleManager ? VehicleManager.activeVehicle : null
                    if (v) v.disarm()
                    disarmDialog.close()
                }
            }
        }
    }
}
