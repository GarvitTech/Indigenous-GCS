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

    // ── Map provider ──────────────────────────────────────────────────────
    // Public OpenStreetMap raster tiles. No API key, no signup, no watermark,
    // no account — the map works on a fresh clone with no configuration.
    readonly property string tileHost:
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"

    Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
        PluginParameter { name: "osm.mapping.custom.host"; value: root.tileHost }
        PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: "" }
        PluginParameter { name: "osm.mapping.custom.datacopyright"; value: "" }
        PluginParameter { name: "osm.useragent"; value: "IndigenousGCS/1.0 (QtLocation)" }
    }

    // Select the "Custom URL Map" provider so tiles come from the plain
    // OpenStreetMap tile server rather than the default token-gated endpoint
    // (which renders an "API Key Required" watermark across every tile).
    // supportedMapTypes is populated asynchronously by the plugin, so this is
    // safe to call more than once.
    function applyOsmBaseMap() {
        var types = osmPlugin.supportedMapTypes
        if (!types || types.length === 0)
            return false
        for (var i = 0; i < types.length; ++i) {
            // style 100 === MapType.CustomMap
            if (types[i].style === MapType.CustomMap || types[i].style === 100) {
                if (missionMap.activeMapType !== types[i])
                    missionMap.activeMapType = types[i]
                return true
            }
        }
        // If the plugin never exposes a CustomMap type (e.g. the provider
        // repository could not be fetched), fall back to the first non-token
        // type so we never render the "API Key Required" default.
        var fallback = null
        for (var j = 0; j < types.length; ++j) {
            if (types[j].style === MapType.StreetMap) { fallback = types[j]; break }
            if (fallback === null) fallback = types[j]
        }
        if (fallback !== null && missionMap.activeMapType !== fallback)
            missionMap.activeMapType = fallback
        return fallback !== null
    }

    // Fallback retry in case the signal fires before missionMap is ready.
    Timer {
        interval: 400; repeat: true; running: true; triggeredOnStart: true
        property int attempts: 0
        onTriggered: {
            if (applyOsmBaseMap() || ++attempts >= 8)
                running = false
        }
    }

    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null
    // QML can observe `vehicle` a moment before its Telemetry child is usable,
    // so every read goes through this guarded accessor instead of chaining
    // `vehicle.telemetry.xxx` directly (which produced "Cannot read property
    // 'latitude' of undefined" while the vehicle was still being built up).
    readonly property var vehicleTelemetry: (vehicle && vehicle.telemetry) ? vehicle.telemetry : null
    property string operationNotice: ""
    property bool placingWaypoint: false
    readonly property bool transferInProgress: MissionManager.transferState === 1
                                                || MissionManager.transferState === 2
                                                || MissionManager.transferState === 5

    // ── Initial map centre ────────────────────────────────────────────────────
    // Resolved once from this computer's public IP so the planner opens on the
    // operator's own area instead of a hardcoded city. Falls back to New Delhi
    // when the lookup fails (offline, behind a proxy, or rate-limited).
    property real   homeLatitude:  28.6139
    property real   homeLongitude: 77.2090
    property string homeLabel:     "default"

    Component.onCompleted: {
        const loc = AppSettings.detectLocation()
        if (loc && loc.valid) {
            homeLatitude  = loc.latitude
            homeLongitude = loc.longitude
            homeLabel     = loc.city ? loc.city : "detected"
            missionMap.center = QtPositioning.coordinate(homeLatitude, homeLongitude)
        }
    }

    Connections {
        target: MissionManager
        function onTransferFailed(reason) {
            root.operationNotice = reason
            operationDialog.title = "Mission operation failed"
            operationDialog.message = reason
            operationDialog.open()
        }
        function onUploadComplete() { root.operationNotice = "Mission uploaded and acknowledged by the flight controller." }
        function onDownloadComplete() { root.operationNotice = "Mission downloaded from the flight controller." }
        function onClearComplete() { root.operationNotice = "Flight-controller mission cleared and acknowledged." }
    }
    readonly property bool physicalVehicleConnected: vehicle !== null && !vehicle.simulated

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacingM }
        spacing: Theme.spacingM

        // --- TOOLBAR ---
        RowLayout {
            spacing: Theme.spacingS
            Text { text: "MISSION PLANNER"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }

            IGButton { text: "NEW"; implicitWidth: 70; onClicked: MissionManager.mission.clear() }
            IGButton { text: "VALIDATE"; implicitWidth: 80; onClicked: root.validateMission() }
            IGButton { text: "UPLOAD"; implicitWidth: 80; enabled: root.physicalVehicleConnected && !root.transferInProgress
                onClicked: { if (vehicle) MissionManager.uploadMission(vehicle.sysId, vehicle.compId) } }
            IGButton { text: "DOWNLOAD"; implicitWidth: 90; enabled: root.physicalVehicleConnected && !root.transferInProgress
                onClicked: { if (vehicle) MissionManager.downloadMission(vehicle.sysId, vehicle.compId) } }
            IGButton { text: "CLEAR FC"; implicitWidth: 80; danger: true; enabled: root.physicalVehicleConnected && !root.transferInProgress
                onClicked: clearConfirm.open() }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: noticeText.implicitHeight + Theme.spacingS * 2
            color: vehicle ? Colors.bg2 : Colors.warning
            radius: Theme.radiusSmall
            visible: true
            Text {
                id: noticeText
                anchors { fill: parent; margins: Theme.spacingS }
                text: root.operationNotice.length > 0 ? root.operationNotice
                     : vehicle ? (vehicle.simulated
                                  ? "SIMULATION ACTIVE (system " + vehicle.sysId + ") — not a flight-controller connection. Stop the simulator and connect a controller in Diagnostics."
                                  : "Flight controller detected (system " + vehicle.sysId + "). Mission validation works offline.")
                               : "Validation works offline. To download or upload, connect in Diagnostics and wait for a vehicle heartbeat."
                color: vehicle || root.operationNotice.length > 0 ? Colors.textSecondary : Colors.bg0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Transfer progress bar (Animated)
        Rectangle {
            Layout.fillWidth: true; height: 24
            color: Colors.bg2; radius: Theme.radiusSmall
            border.color: Colors.border; border.width: 1
            visible: MissionManager.transferState !== 0
            clip: true

            Rectangle {
                id: progressFill
                width: parent.width * (MissionManager.transferProgress / 100)
                height: parent.height; radius: parent.radius
                color: MissionManager.transferState === 3 ? Colors.ok
                     : MissionManager.transferState === 4 ? Colors.critical : Colors.accent
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            }
            Text {
                anchors.centerIn: parent
                text: {
                    switch(MissionManager.transferState) {
                    case 1: return "Uploading... " + MissionManager.transferProgress + "%"
                    case 2: return "Downloading... " + MissionManager.transferProgress + "%"
                    case 3: return "Transfer complete"
                    case 4: return "Transfer failed"
                    case 5: return "Waiting for flight-controller clear acknowledgement..."
                    default: return ""
                    }
                }
                color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
            }
        }

        // --- MAIN CONTENT AREA ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingM

            // LEFT: The Map (Pro Ardupilot Style)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.bg1
                radius: Theme.radiusSmall
                border.color: Colors.border
                border.width: 1
                clip: true

                Map {
                    id: missionMap
                    anchors.fill: parent
                    // Free OpenStreetMap tiles via the OSM plugin: no API key required.
                    // The provider is kept abstract (see docs) so a paid tile service can
                    // be substituted later without touching this page.
                    plugin: osmPlugin
                    Component.onCompleted: applyOsmBaseMap()
                    // Opens on this computer's area (see Component.onCompleted on
                    // the page root); New Delhi is only the pre-detection default.
                    center: QtPositioning.coordinate(28.6139, 77.2090)
                    zoomLevel: 14

                    // ── Google-Maps-style interaction ────────────────────────
                    // Qt's OSM plugin already pans on left-drag, but the default
                    // gesture arbitration loses the drag as soon as a child item
                    // (a waypoint marker) is under the cursor. These handlers sit
                    // above the map content and claim the gestures explicitly so
                    // dragging anywhere — including over a marker — pans the map,
                    // and the wheel zooms about the cursor rather than the centre.

                    // Pan: follow the pointer while a left button is held.
                    DragHandler {
                        id: panHandler
                        target: null
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        // Only take over once the pointer has actually moved, so a
                        // plain click still reaches the waypoint-placement handler.
                        dragThreshold: 4

                        property real lastX: 0
                        property real lastY: 0

                        onActiveChanged: {
                            if (active) {
                                lastX = centroid.position.x
                                lastY = centroid.position.y
                            }
                        }

                        onCentroidChanged: {
                            if (!active) return
                            const dx = centroid.position.x - lastX
                            const dy = centroid.position.y - lastY
                            if (dx === 0 && dy === 0) return

                            // Translate the drag in screen pixels into a shift of
                            // the map centre, in degrees, at the current zoom.
                            const c = missionMap.toCoordinate(
                                Qt.point(missionMap.width / 2, missionMap.height / 2), false)
                            const dx2 = missionMap.toCoordinate(
                                Qt.point(missionMap.width / 2 + dx, missionMap.height / 2), false)
                            const dy2 = missionMap.toCoordinate(
                                Qt.point(missionMap.width / 2, missionMap.height / 2 + dy), false)

                            if (c.isValid && dx2.isValid && dy2.isValid) {
                                missionMap.center = QtPositioning.coordinate(
                                    c.latitude  - (dy2.latitude  - c.latitude),
                                    c.longitude - (dx2.longitude - c.longitude))
                            }

                            lastX = centroid.position.x
                            lastY = centroid.position.y
                        }
                    }

                    // Zoom: wheel about the cursor, so the point under the
                    // pointer stays put — the behaviour people expect from a
                    // web map rather than zooming about the viewport centre.
                    WheelHandler {
                        id: wheelHandler
                        target: null
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                        onWheel: function (event) {
                            const delta = event.angleDelta.y
                            if (delta === 0) return

                            const step = delta > 0 ? 1 : -1
                            const newZoom = Math.max(2, Math.min(19, missionMap.zoomLevel + step))
                            if (newZoom === missionMap.zoomLevel) return

                            // Anchor the zoom on the cursor position.
                            const before = missionMap.toCoordinate(event.position, false)
                            missionMap.zoomLevel = newZoom
                            if (before.isValid) {
                                const after = missionMap.toCoordinate(event.position, false)
                                if (after.isValid) {
                                    missionMap.center = QtPositioning.coordinate(
                                        missionMap.center.latitude  + (before.latitude  - after.latitude),
                                        missionMap.center.longitude + (before.longitude - after.longitude))
                                }
                            }
                            event.accepted = true
                        }
                    }

                    // Trackpad pinch (macOS) and touch pinch.
                    PinchHandler {
                        id: pinchHandler
                        target: null
                        onActiveScaleChanged: {
                            missionMap.zoomLevel = Math.max(2,
                                Math.min(19, missionMap.zoomLevel + Math.log2(activeScale)))
                        }
                    }


                    MapPolyline {
                        line.width: 3
                        line.color: Colors.accent
                        path: MissionManager.mission
                              ? MissionManager.mission.waypointList.map(function(wp) {
                                    return QtPositioning.coordinate(wp.latitude, wp.longitude)
                                })
                              : []
                    }

                    // Vehicle Marker
                    MapQuickItem {
                        visible: root.vehicleTelemetry !== null
                                 && root.vehicleTelemetry.gpsFixType >= 2
                        coordinate: visible
                            ? QtPositioning.coordinate(root.vehicleTelemetry.latitude,
                                                       root.vehicleTelemetry.longitude)
                            : QtPositioning.coordinate(0, 0)
                        anchorPoint: Qt.point(7, 7)
                        sourceItem: Rectangle {
                            width: 14; height: 14; radius: 7; color: Colors.accentBlue
                            border.color: "white"; border.width: 2
                        }
                    }

                    // Waypoints
                    MapItemView {
                        model: MissionManager.mission ? MissionManager.mission.waypointList : []
                        delegate: MapQuickItem {
                            required property var modelData
                            coordinate: QtPositioning.coordinate(modelData.latitude, modelData.longitude)
                            anchorPoint: Qt.point(8, 8)
                            sourceItem: Column {
                                Rectangle { width: 16; height: 16; radius: 8; color: Colors.accent; border.color: Colors.bg0; border.width: 2; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: modelData.seq + 1; color: Colors.textPrimary; font.pixelSize: 10; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }

                    TapHandler {
                        enabled: root.placingWaypoint
                        // Only claim a clean left-click; drags are left to the map so
                        // panning and zooming behave like Google Maps.
                        gesturePolicy: TapHandler.DragThreshold
                        acceptedButtons: Qt.LeftButton
                        onTapped: function(eventPoint) {
                            const coordinate = missionMap.toCoordinate(eventPoint.position, false)
                            if (!coordinate.isValid || coordinate.latitude < -90 || coordinate.latitude > 90
                                    || coordinate.longitude < -180 || coordinate.longitude > 180)
                                return
                            const altitude = parseFloat(altField.text)
                            MissionManager.mission.addWaypoint(
                                coordinate.latitude, coordinate.longitude,
                                isFinite(altitude) ? altitude : 10)
                            root.placingWaypoint = false
                        }
                    }

                    Row {
                        anchors { top: parent.top; right: parent.right; margins: Theme.spacingS }
                        spacing: Theme.spacingS
                        IGButton {
                            text: root.placingWaypoint ? "CANCEL PLACEMENT" : "ADD WAYPOINT"
                            implicitWidth: root.placingWaypoint ? 150 : 120
                            active: root.placingWaypoint
                            onClicked: root.placingWaypoint = !root.placingWaypoint
                        }
                        IGButton {
                            text: "RELOAD MAP"
                            implicitWidth: 110
                            secondary: true
                            // Qt caches plugin parameters at construction, so a key
                            // pasted in Settings only takes effect once the map page
                            // is rebuilt. Re-assigning the source component does that
                            // safely (no dangling plugin pointer, unlike a Loader).
                            onClicked: {
                                var src = pageLoader.sourceComponent
                                pageLoader.sourceComponent = null
                                pageLoader.sourceComponent = src
                            }
                        }
                        IGButton {
                            text: "CENTER VEHICLE"
                            implicitWidth: 130
                            visible: root.vehicleTelemetry !== null
                                     && root.vehicleTelemetry.gpsFixType >= 2
                            onClicked: {
                                missionMap.center = QtPositioning.coordinate(
                                    root.vehicleTelemetry.latitude, root.vehicleTelemetry.longitude)
                                missionMap.zoomLevel = 16
                            }
                        }
                        // Returns to the area the map opened on — this computer's
                        // location when it could be resolved, otherwise the default.
                        IGButton {
                            text: "MY LOCATION"
                            implicitWidth: 118
                            secondary: true
                            onClicked: {
                                missionMap.center = QtPositioning.coordinate(
                                    root.homeLatitude, root.homeLongitude)
                                missionMap.zoomLevel = 15
                            }
                        }
                    }

                    // On-screen zoom controls (map is also zoomable via wheel/pinch).
                    Column {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spacingS }
                        spacing: Theme.spacingXS
                        IGButton {
                            text: "+"; implicitWidth: 34; implicitHeight: 30; secondary: true
                            onClicked: missionMap.zoomLevel = Math.min(missionMap.zoomLevel + 1, missionMap.maximumZoomLevel)
                        }
                        IGButton {
                            text: "−"; implicitWidth: 34; implicitHeight: 30; secondary: true
                            onClicked: missionMap.zoomLevel = Math.max(missionMap.zoomLevel - 1, missionMap.minimumZoomLevel)
                        }
                    }

                    // Placement-mode hint so the click-to-add flow is discoverable.
                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spacingS }
                        visible: root.placingWaypoint
                        color: Colors.accent; radius: Theme.radiusSmall
                        width: hintText.implicitWidth + Theme.spacingM * 2
                        height: hintText.implicitHeight + Theme.spacingS
                        Text {
                            id: hintText
                            anchors.centerIn: parent
                            text: "Click the map to place waypoint " + (MissionManager.mission ? MissionManager.mission.waypointList.length + 1 : 1)
                            color: Colors.bg0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                        }
                    }

                }
            }

            // RIGHT: The Waypoint Table (Mission Planner Style)
            Rectangle {
                Layout.preferredWidth: 450
                Layout.fillHeight: true
                color: Colors.bg2
                radius: Theme.radiusSmall
                border.color: Colors.border
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent; spacing: 0

                    // Waypoint Addition Form
                    Rectangle {
                        Layout.fillWidth: true; height: 70
                        color: Colors.bg3; radius: Theme.radiusSmall
                        border.color: Colors.border; border.width: 1

                        GridLayout {
                            anchors.fill: parent; anchors.margins: Theme.spacingS
                            columns: 2
                            rowSpacing: 8
                            columnSpacing: 8

                            TextField {
                                id: latField; placeholderText: "Latitude"; Layout.fillWidth: true
                                color: Colors.textPrimary; background: Rectangle { color: Colors.bg2; radius: 2; border.color: Colors.border }
                            }
                            TextField {
                                id: lonField; placeholderText: "Longitude"; Layout.fillWidth: true
                                color: Colors.textPrimary; background: Rectangle { color: Colors.bg2; radius: 2; border.color: Colors.border }
                            }
                            TextField {
                                id: altField; placeholderText: "Altitude (m)"; text: "10"; Layout.fillWidth: true
                                color: Colors.textPrimary; background: Rectangle { color: Colors.bg2; radius: 2; border.color: Colors.border }
                            }
                            IGButton {
                                text: "ADD WAYPOINT"; Layout.fillWidth: true
                                onClicked: {
                                    const lat = parseFloat(latField.text)
                                    const lon = parseFloat(lonField.text)
                                    const alt = parseFloat(altField.text)
                                    if (!isNaN(lat) && !isNaN(lon) && !isNaN(alt))
                                        MissionManager.mission.addWaypoint(lat, lon, alt)
                                }
                            }
                        }
                    }

                    // Table Header
                    Rectangle {
                        Layout.fillWidth: true; height: 35; color: Colors.bg1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: Theme.spacingS
                            Text { text: "SEQ"; color: Colors.textDisabled; font.bold: true; Layout.preferredWidth: 40 }
                            Text { text: "CMD"; color: Colors.textDisabled; font.bold: true; Layout.preferredWidth: 100 }
                            Text { text: "LAT"; color: Colors.textDisabled; font.bold: true; Layout.preferredWidth: 120 }
                            Text { text: "LON"; color: Colors.textDisabled; font.bold: true; Layout.preferredWidth: 120 }
                            Text { text: "ALT"; color: Colors.textDisabled; font.bold: true; Layout.preferredWidth: 60 }
                            Text { text: "ACT"; color: Colors.textDisabled; font.bold: true; Layout.preferredWidth: 50 }
                        }
                    }

                    // Waypoint List
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        model: MissionManager.mission ? MissionManager.mission.waypointList : []
                        clip: true
                        delegate: Rectangle {
                            width: ListView.view.width; height: 35
                            color: index % 2 === 0 ? Colors.bg2 : Colors.bg3
                            border.color: Colors.border; border.width: 0.5

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: Theme.spacingS
                                Text { text: modelData.seq; color: Colors.textSecondary; Layout.preferredWidth: 40 }
                                Text { text: modelData.commandName; color: Colors.textPrimary; Layout.preferredWidth: 100 }
                                Text { text: modelData.latitude.toFixed(6); color: Colors.textPrimary; Layout.preferredWidth: 120 }
                                Text { text: modelData.longitude.toFixed(6); color: Colors.textPrimary; Layout.preferredWidth: 120 }
                                Text { text: modelData.altitude.toFixed(1); color: Colors.textPrimary; Layout.preferredWidth: 60 }
                                IGButton {
                                    text: "✕"; implicitWidth: 30; implicitHeight: 24; danger: true
                                    onClicked: MissionManager.mission.removeWaypoint(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function validateMission() {
        if (!MissionManager.mission) {
            root.operationNotice = "Mission data is unavailable."
            return
        }
        const errors = MissionManager.mission.validate()
        validationDialog.errors = errors
        root.operationNotice = errors.length === 0
                ? "Mission validation passed. The plan is ready to upload."
                : "Mission validation failed: " + errors.join("; ")
        validationDialog.open()
    }

    Dialog {
        id: clearConfirm
        title: "Clear flight-controller mission?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Cancel | Dialog.Yes
        // Explicit width avoids the implicitWidth binding loop that a fixed-width
        // contentItem would otherwise create against Dialog's own sizing.
        implicitWidth: 400
        implicitHeight: 180
        onAccepted: {
            if (root.physicalVehicleConnected)
                MissionManager.clearMission(vehicle.sysId, vehicle.compId)
            else
                root.operationNotice = "A real flight-controller heartbeat is required. The simulator cannot clear a controller mission."
        }
        contentItem: Text {
            text: "This sends a clear request to the connected controller. The local plan is kept unless the controller acknowledges the request."
            color: Colors.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            wrapMode: Text.WordWrap
            width: 360
        }
        background: Rectangle { color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1 }
    }

    Dialog {
        id: operationDialog
        property string message: ""
        title: "Mission operation"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
        implicitWidth: 400
        implicitHeight: 180
        contentItem: Text {
            text: operationDialog.message
            color: Colors.critical
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            wrapMode: Text.WordWrap
            width: 360
        }
        background: Rectangle { color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1 }
    }

    Dialog {
        id: validationDialog
        property var errors: []
        title: errors.length === 0 ? "Mission Valid" : "Validation Errors"
        modal: true; anchors.centerIn: Overlay.overlay
        background: Rectangle { color: Colors.bg2; radius: Theme.radiusMedium; border.color: Colors.border; border.width: 1 }
        standardButtons: Dialog.Ok
        contentItem: Text {
            text: validationDialog.errors.length === 0
                  ? "Mission is valid and ready to upload."
                  : validationDialog.errors.join(", ")
            color: validationDialog.errors.length === 0 ? Colors.ok : Colors.critical
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
            wrapMode: Text.WordWrap
            width: 360
        }
    }
}

