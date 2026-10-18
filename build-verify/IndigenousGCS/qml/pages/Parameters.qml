import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property var vehicle: VehicleManager && VehicleManager.activeVehicle
                          ? VehicleManager.activeVehicle : null
    property string selectedGroup: "ALL"
    property var    fullParamList:  []
    property var    displayList:    []
    property var    modifiedParams: ({})
    property int    modifiedCount:  0
    property string searchText:     ""

    // Build full list and groups from backend
    function refresh() {
        if (!ParameterManager) { fullParamList = []; displayList = []; return }
        const names = ParameterManager.parameterNames()
        fullParamList = names
        applyFilter()
    }

    function applyFilter() {
        const q   = searchText.toLowerCase()
        const grp = selectedGroup
        displayList = fullParamList.filter(function(n) {
            if (grp !== "ALL") {
                const pfx = n.indexOf("_") > 0 ? n.substring(0, n.indexOf("_")) : n
                if (pfx !== grp) return false
            }
            return q.length === 0 || n.toLowerCase().indexOf(q) !== -1
        })
    }

    // Build sorted group list
    function buildGroups() {
        const counts = {}
        for (const n of fullParamList) {
            const pfx = n.indexOf("_") > 0 ? n.substring(0, n.indexOf("_")) : "OTHER"
            counts[pfx] = (counts[pfx] || 0) + 1
        }
        const grps = Object.keys(counts).sort()
        grps.unshift("ALL")
        return grps.map(function(k) { return { name: k, count: k === "ALL" ? fullParamList.length : counts[k] } })
    }

    Connections {
        target: ParameterManager
        // ParameterManager emits parametersChanged() as PARAM_VALUE messages
        // arrive, so the table fills progressively during a download.
        function onParametersChanged() { root.refresh() }
        function onIsDownloadingChanged() { root.refresh() }
        function onParameterUpdated(name) {
            // A single parameter changed — refresh its row without rebuilding
            // the whole model, so an in-progress edit is not disrupted.
            root.refresh()
        }
    }
    onVehicleChanged: { if (!vehicle) { fullParamList = []; displayList = []; modifiedParams = {}; modifiedCount = 0 } }
    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── TOP TOOLBAR ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 46
            color: Colors.bg1
            border.color: Colors.border; border.width: 0
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1; color: Colors.border
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Theme.spacingM
                    rightMargin: Theme.spacingM
                }
                spacing: Theme.spacingS

                Text {
                    text: "PARAMETERS"
                    color: Colors.accent
                    font.pixelSize: Theme.fontSizeMedium
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.letterSpacing: 3
                }

                TextField {
                    id: searchBar
                    Layout.fillWidth: true
                    implicitHeight: 30
                    placeholderText: "Search parameters..."
                    color: Colors.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    leftPadding: 10
                    background: Rectangle {
                        color: Colors.bg2
                        radius: Theme.radiusSmall
                        border.color: searchBar.activeFocus ? Colors.accent : Colors.border
                        border.width: 1
                    }
                    onTextChanged: { root.searchText = text; root.applyFilter() }
                }

                // Count pill
                Rectangle {
                    width: cntLabel.implicitWidth + 16; height: 26
                    color: Colors.bg3
                    radius: Theme.radiusSmall
                    border.color: ParameterManager && ParameterManager.loading ? Colors.warning :
                                  (root.fullParamList.length > 0 ? Colors.ok : Colors.border)
                    border.width: 1
                    Text {
                        id: cntLabel
                        anchors.centerIn: parent
                        text: ParameterManager && ParameterManager.loading
                              ? (ParameterManager.receivedCount + " / " + ParameterManager.totalCount)
                              : (root.displayList.length + " / " + root.fullParamList.length)
                        color: ParameterManager && ParameterManager.loading ? Colors.warning :
                               (root.fullParamList.length > 0 ? Colors.ok : Colors.textDisabled)
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        font.bold: true
                    }
                }

                IGButton {
                    text: ParameterManager && ParameterManager.loading ? "DOWNLOADING…" : "REQUEST"
                    implicitWidth: 100
                    enabled: root.vehicle !== null && !(root.vehicle && root.vehicle.simulated)
                             && !(ParameterManager && ParameterManager.loading)
                    onClicked: { if (root.vehicle) ParameterManager.requestAll(root.vehicle.sysId, root.vehicle.compId) }
                }

                IGButton {
                    text: "EXPORT"
                    implicitWidth: 76
                    secondary: true
                    enabled: root.fullParamList.length > 0
                    onClicked: ParameterManager.exportParameters("")
                }
            }
        }

        // ── DOWNLOAD PROGRESS BAR ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: Colors.bg3
            visible: ParameterManager && ParameterManager.loading
            Rectangle {
                width: ParameterManager && ParameterManager.totalCount > 0
                       ? parent.width * ParameterManager.receivedCount / ParameterManager.totalCount : 0
                height: parent.height
                color: Colors.accent
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        // ── BODY ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ── LEFT PANEL: Groups ─────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Colors.bg1
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                    }
                    width: 1; color: Colors.border
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; height: 30
                        color: Colors.bg2
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1
                            color: Colors.border
                        }
                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: Theme.spacingM
                                verticalCenter: parent.verticalCenter
                            }
                            text: "GROUPS"; color: Colors.textDisabled
                            font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 2
                        }
                    }

                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true
                        model: root.buildGroups()
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Rectangle {
                            width: ListView.view.width; height: 36
                            color: root.selectedGroup === modelData.name
                                   ? Colors.accentGlow : (grpHov.containsMouse ? Colors.bg2 : "transparent")
                            // Active indicator
                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: 3
                                color: root.selectedGroup === modelData.name ? Colors.accent : "transparent"
                            }
                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 14
                                    rightMargin: Theme.spacingS
                                }
                                spacing: Theme.spacingS
                                Text {
                                    text: modelData.name
                                    color: root.selectedGroup === modelData.name ? Colors.accent : Colors.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                                    font.bold: root.selectedGroup === modelData.name
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: cntBadge.implicitWidth + 8; height: 16
                                    color: Colors.bg3; radius: 8
                                    Text {
                                        id: cntBadge; anchors.centerIn: parent
                                        text: modelData.count.toString()
                                        color: Colors.textSecondary
                                        font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily
                                    }
                                }
                            }
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 1
                                color: Colors.border
                                opacity: 0.3
                            }
                            HoverHandler { id: grpHov }
                            TapHandler {
                                onTapped: { root.selectedGroup = modelData.name; root.applyFilter() }
                            }
                        }
                    }
                }
            }

            // ── RIGHT PANEL: Parameter table ───────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // No vehicle message
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: Colors.bg0; visible: !root.vehicle
                    Column {
                        anchors.centerIn: parent; spacing: Theme.spacingM
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "⚙"
                            color: Colors.textDisabled
                            font.pixelSize: 48
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter
                            text: "Connect a vehicle to view parameters"
                            color: Colors.textDisabled; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily
                        }
                    }
                }

                // Column headers
                Rectangle {
                    Layout.fillWidth: true; height: 32
                    color: Colors.bg1; visible: root.vehicle !== null
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 2
                        color: Colors.accent
                        opacity: 0.5
                    }
                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: Theme.spacingS
                        }
                        spacing: 0
                        Text {
                            text: "PARAMETER"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.preferredWidth: 200
                        }
                        Text {
                            text: "VALUE"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.preferredWidth: 140
                        }
                        Text {
                            text: "TYPE"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.preferredWidth: 60
                        }
                        Text {
                            text: "STATUS"
                            color: Colors.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                }

                // Empty state
                Rectangle {
                    Layout.fillWidth: true; height: 60
                    color: Colors.bg0; visible: root.vehicle !== null && root.displayList.length === 0 && !ParameterManager.loading
                    Text {
                        anchors.centerIn: parent
                        text: root.fullParamList.length === 0
                              ? "Click REQUEST to download parameters from the flight controller"
                              : "No parameters match \"" + root.searchText + "\""
                        color: Colors.textDisabled; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily
                    }
                }

                // Parameter ListView
                ListView {
                    id: paramView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: root.vehicle !== null
                    model: root.displayList
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    cacheBuffer: 200

                    delegate: Rectangle {
                        id: pRow
                        width: paramView.width
                        height: 38
                        color: index % 2 === 0 ? Colors.bg2 : Colors.bg3

                        property string pName:   modelData
                        property string origVal: ParameterManager ? (ParameterManager.getParameter(pName) !== undefined ? ParameterManager.getParameter(pName).toString() : "—") : "—"
                        property bool   isModified: root.modifiedParams[pName] !== undefined
                        property bool   justSent:   false

                        // Left modified indicator strip
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: 3
                            color: pRow.justSent ? Colors.ok : (pRow.isModified ? Colors.warning : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: Theme.spacingS
                            }
                            spacing: 0

                            // Parameter name
                            Text {
                                text: pRow.pName
                                color: pRow.isModified ? Colors.warning : Colors.textPrimary
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: "monospace"
                                Layout.preferredWidth: 196
                                elide: Text.ElideRight
                                ToolTip.visible: nameHov.containsMouse && implicitWidth > 196
                                ToolTip.text: pRow.pName
                                HoverHandler { id: nameHov }
                            }

                            // Editable value
                            TextField {
                                id: valField
                                Layout.preferredWidth: 132
                                implicitHeight: 28
                                text: pRow.origVal
                                color: pRow.isModified ? Colors.warning : Colors.accent
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                verticalAlignment: TextInput.AlignVCenter
                                leftPadding: 6
                                selectByMouse: true
                                background: Rectangle {
                                    color: pRow.isModified ? "#1a1200" : Colors.bg1
                                    radius: 3
                                    border.color: valField.activeFocus ? Colors.accent
                                                : (pRow.isModified ? Colors.warning : Colors.border)
                                    border.width: 1
                                }
                                onEditingFinished: {
                                    const newVal = text.trim()
                                    if (newVal === pRow.origVal || newVal === "—") return
                                    const numVal = parseFloat(newVal)
                                    if (isNaN(numVal)) return
                                    // Mark modified
                                    const mp = root.modifiedParams
                                    mp[pRow.pName] = numVal
                                    root.modifiedParams = mp
                                    root.modifiedCount = Object.keys(mp).length
                                    // Send immediately if vehicle connected
                                    if (root.vehicle && !root.vehicle.simulated) {
                                        ParameterManager.setParameter(root.vehicle.sysId, root.vehicle.compId, pRow.pName, numVal)
                                        pRow.justSent = true
                                        sentTimer.restart()
                                    }
                                }
                                Timer {
                                    id: sentTimer; interval: 2000
                                    onTriggered: {
                                        pRow.justSent = false
                                        // Clear from modified map
                                        const mp = root.modifiedParams
                                        delete mp[pRow.pName]
                                        root.modifiedParams = mp
                                        root.modifiedCount  = Object.keys(mp).length
                                    }
                                }
                            }

                            // Type chip
                            Rectangle {
                                Layout.preferredWidth: 56
                                height: 20
                                color: Colors.bg1
                                radius: 3
                                border.color: Colors.border; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "FLOAT"
                                    color: Colors.textDisabled
                                    font.pixelSize: Theme.fontSizeTiny
                                    font.family: Theme.fontFamily
                                }
                            }

                            // Status
                            Text {
                                Layout.fillWidth: true
                                text: pRow.justSent ? "✓ SENT" : (pRow.isModified ? "● MODIFIED" : "")
                                color: pRow.justSent ? Colors.ok : Colors.warning
                                font.pixelSize: Theme.fontSizeTiny
                                font.family: Theme.fontFamily
                                font.bold: true
                                leftPadding: 6
                            }
                        }
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1
                            color: Colors.border
                            opacity: 0.3
                        }
                    }
                }
            }
        }

        // ── BOTTOM BAR ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: Colors.bg1
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: Colors.border
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Theme.spacingM
                    rightMargin: Theme.spacingM
                }
                spacing: Theme.spacingS

                // Pulse dot when downloading
                Rectangle {
                    width: 8; height: 8; radius: 4
                    visible: ParameterManager && ParameterManager.loading
                    color: Colors.warning
                    SequentialAnimation on opacity {
                        running: ParameterManager && ParameterManager.loading; loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.2
                            duration: 400
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 400
                        }
                    }
                }

                Text {
                    text: {
                        if (ParameterManager && ParameterManager.loading)
                            return "Downloading…  " + ParameterManager.receivedCount + " of " + ParameterManager.totalCount
                        if (root.fullParamList.length > 0)
                            return root.fullParamList.length + " parameters loaded" +
                                   (root.modifiedCount > 0 ? "  |  " + root.modifiedCount + " modified" : "")
                        return root.vehicle ? "No parameters — click REQUEST" : "No vehicle connected"
                    }
                    color: Colors.textSecondary
                    font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily
                }

                Item { Layout.fillWidth: true }

                IGButton {
                    text: "SEND ALL CHANGES"
                    implicitWidth: 140
                    baseColor: Colors.warning
                    textColor: Colors.bg0
                    visible: root.modifiedCount > 0 && root.vehicle && !root.vehicle.simulated
                    onClicked: {
                        for (const [name, val] of Object.entries(root.modifiedParams)) {
                            ParameterManager.setParameter(root.vehicle.sysId, root.vehicle.compId, name, val)
                        }
                        root.modifiedParams = {}
                        root.modifiedCount  = 0
                    }
                }
            }
        }
    }
}
