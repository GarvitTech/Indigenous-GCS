import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../components"
import "../theme"

Rectangle {
    id: root
    color: Colors.bg0

    property var vehicle: VehicleManager ? VehicleManager.activeVehicle : null

    // Board-selection helpers live at root scope so every part of the page can
    // call them. Previously they were nested inside the editor's control block,
    // which left the board picker label (a different subtree) unable to resolve
    // selectedBoardName() — it silently rendered as undefined.
    function syncBoardSelection() {
        if (FirmwareManager.selectedBoard.length === 0 && FirmwareManager.boardPickerItems.length > 0)
            FirmwareManager.selectedBoard = FirmwareManager.boardPickerItems[0].fqbn
    }

    function selectedBoardName() {
        const boards = FirmwareManager.boardPickerItems
        for (let i = 0; i < boards.length; ++i) {
            if (boards[i].fqbn === FirmwareManager.selectedBoard)
                return boards[i].name
        }
        return boards.length > 0 ? "Select a board" : "No platform boards installed"
    }

    Component.onCompleted: syncBoardSelection()

    // ── Connections ──────────────────────────────────────────────────────────
    Connections {
        target: FirmwareManager
        function onOperationSucceeded(msg) { statusBanner.show(msg, false) }
        function onOperationFailed(msg)    { statusBanner.show(msg, true)  }
        function onCompileLogChanged()     { compileLogView.text = FirmwareManager.compileLog; compileLogView.cursorPosition = compileLogView.length }
        function onFlashLogChanged()       { flashLogView.text   = FirmwareManager.flashLog;   flashLogView.cursorPosition   = flashLogView.length   }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Top toolbar ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: Theme.toolBarHeight
            color: Colors.bg1
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }

            RowLayout {
                anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                spacing: Theme.spacingS

                Text { text: "⬡"; color: Colors.accent; font.pixelSize: 18 }
                Text { text: "FIRMWARE TOOL"; color: Colors.accent; font.pixelSize: Theme.fontSizeMedium; font.family: Theme.fontFamily; font.bold: true; font.letterSpacing: 2 }
                Text { text: "Arduino → Binary → ESP32"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }

                Item { Layout.fillWidth: true }

                // Status banner
                Rectangle {
                    id: statusBanner
                    visible: false; radius: Theme.radiusSmall
                    width: bannerTxt.implicitWidth + 20; height: 24
                    color: bannerIsError ? "#3a0000" : "#003a00"
                    border.color: bannerIsError ? Colors.critical : Colors.ok; border.width: 1
                    property bool bannerIsError: false
                    Text { id: bannerTxt; anchors.centerIn: parent; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.bold: true
                        color: parent.bannerIsError ? Colors.critical : Colors.ok }
                    Timer { id: bannerTimer; interval: 5000; onTriggered: statusBanner.visible = false }
                    function show(msg, isError) { bannerTxt.text = msg; bannerIsError = isError; visible = true; bannerTimer.restart() }
                }
            }
        }

        // ── Main content ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ── LEFT: Code editor + controls ─────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.55
                Layout.fillHeight: true
                spacing: 0

                // Config bar
                Rectangle {
                    Layout.fillWidth: true; height: 76
                    color: Colors.bg2
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1; color: Colors.border }

                    ColumnLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS
                            Text { text: "BOARD:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }

                            Rectangle {
                                id: boardPicker
                                property bool popupOpen: false
                                property string searchText: ""
                                property var filteredItems: {
                                    const query = searchText.trim().toLowerCase()
                                    const boards = FirmwareManager.boardPickerItems
                                    if (!query)
                                        return boards
                                    return boards.filter(function(board) {
                                        return board.name.toLowerCase().indexOf(query) >= 0
                                            || board.category.toLowerCase().indexOf(query) >= 0
                                            || board.fqbn.toLowerCase().indexOf(query) >= 0
                                    })
                                }
                                implicitWidth: 220
                                implicitHeight: 26
                                color: Colors.bg3
                                radius: Theme.radiusSmall
                                border.color: boardPicker.popupOpen ? Colors.accent : Colors.border
                                border.width: 1
                                enabled: FirmwareManager.availableBoards.length > 0

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 7; rightMargin: 7 }
                                    Text {
                                        Layout.fillWidth: true
                                        text: selectedBoardName()
                                        color: boardPicker.enabled ? Colors.accent : Colors.textDisabled
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.family: Theme.fontFamily
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text { text: boardPicker.popupOpen ? "▲" : "▼"; color: Colors.textSecondary; font.pixelSize: 9 }
                                }
                                TapHandler { onTapped: boardPicker.popupOpen = !boardPicker.popupOpen }

                                Popup {
                                    id: boardPopup
                                    // The picker opens by toggling its own flag, so
                                    // the Popup must follow it explicitly.
                                    visible: boardPicker.popupOpen
                                    x: 0
                                    y: boardPicker.height + 3
                                    width: 340
                                    // Fixed height: binding to the column's implicit
                                    // height created a cycle through the filling
                                    // ListView, collapsing the popup to zero and
                                    // hiding every board.
                                    height: 460
                                    padding: 8
                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                    onOpened: { boardPicker.popupOpen = true; boardSearch.forceActiveFocus() }
                                    onClosed: { boardPicker.popupOpen = false; boardPicker.searchText = "" }
                                    background: Rectangle { color: Colors.bg1; border.color: Colors.border; radius: Theme.radiusSmall }
                                    contentItem: ColumnLayout {
                                        id: boardPopupColumn
                                        spacing: 6
                                        TextField {
                                            id: boardSearch
                                            Layout.fillWidth: true
                                            placeholderText: "Search boards and platforms"
                                            text: boardPicker.searchText
                                            onTextChanged: boardPicker.searchText = text
                                            color: Colors.textPrimary
                                            selectByMouse: true
                                            background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border }
                                        }
                                        ListView {
                                            id: boardList
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            clip: true
                                            model: boardPicker.filteredItems
                                            boundsBehavior: Flickable.StopAtBounds
                                            delegate: Item {
                                                required property var modelData
                                                required property int index
                                                readonly property bool newCategory: index === 0
                                                    || modelData.category !== boardPicker.filteredItems[index - 1].category
                                                width: boardList.width
                                                height: newCategory ? 58 : 38

                                                Text {
                                                    anchors { left: parent.left; top: parent.top; leftMargin: 8; topMargin: 4 }
                                                    visible: parent.newCategory
                                                    text: modelData.category
                                                    color: Colors.accentBlue
                                                    font.pixelSize: Theme.fontSizeTiny
                                                    font.family: Theme.fontFamily
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width - 16
                                                }
                                                Rectangle {
                                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                                    height: 34
                                                    radius: 3
                                                    color: boardHover.containsMouse ? Colors.bg3
                                                         : modelData.fqbn === FirmwareManager.selectedBoard ? Colors.accentGlow : "transparent"
                                                    Text {
                                                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 8 }
                                                        text: modelData.name
                                                        color: Colors.textPrimary
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        font.family: Theme.fontFamily
                                                        elide: Text.ElideRight
                                                    }
                                                    HoverHandler { id: boardHover }
                                                    TapHandler {
                                                        onTapped: {
                                                            FirmwareManager.selectedBoard = modelData.fqbn
                                                            boardPopup.close()
                                                        }
                                                    }
                                                }
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                visible: boardList.count === 0
                                                text: "No installed boards match."
                                                color: Colors.textSecondary
                                                font.pixelSize: Theme.fontSizeSmall
                                            }
                                        }
                                    }
                                }
                            }

                            Text { text: "PORT:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }

                            ComboBox {
                                id: portCombo
                                model: FirmwareManager.serialPorts
                                currentIndex: count > 0 ? 0 : -1
                                implicitWidth: 110; implicitHeight: 26
                                onCurrentTextChanged: FirmwareManager.selectedPort = currentText
                                background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                                contentItem: Text { text: portCombo.displayText; color: Colors.accent; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; leftPadding: 6; verticalAlignment: Text.AlignVCenter }
                                delegate: ItemDelegate {
                                    width: portCombo.width
                                    contentItem: Text { text: modelData; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                                    background: Rectangle { color: hovered ? Colors.bg4 : Colors.bg3 }
                                }
                                popup: Popup {
                                    y: portCombo.height; width: portCombo.width
                                    background: Rectangle { color: Colors.bg3; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall }
                                    contentItem: ListView { model: portCombo.delegateModel; clip: true; implicitHeight: contentHeight }
                                }
                            }

                            IGButton { text: "⟳"; implicitWidth: 28; implicitHeight: 26; secondary: true; onClicked: FirmwareManager.refreshSerialPorts() }

                            Text { text: "BAUD:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                            ComboBox {
                                id: baudCombo
                                model: ["921600","460800","230400","115200"]
                                implicitWidth: 80; implicitHeight: 26
                                onCurrentTextChanged: FirmwareManager.flashBaud = parseInt(currentText)
                                background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                                contentItem: Text { text: baudCombo.displayText; color: Colors.accent; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; leftPadding: 6; verticalAlignment: Text.AlignVCenter }
                                delegate: ItemDelegate {
                                    width: baudCombo.width
                                    contentItem: Text { text: modelData; color: Colors.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                                    background: Rectangle { color: hovered ? Colors.bg4 : Colors.bg3 }
                                }
                                popup: Popup {
                                    y: baudCombo.height; width: baudCombo.width
                                    background: Rectangle { color: Colors.bg3; border.color: Colors.border; border.width: 1; radius: Theme.radiusSmall }
                                    contentItem: ListView { model: baudCombo.delegateModel; clip: true; implicitHeight: contentHeight }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS
                            Text { text: "ARDUINO CLI:"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily }
                            TextField {
                                id: arduinoCliPathField
                                Layout.fillWidth: true
                                implicitHeight: 24
                                text: FirmwareManager.arduinoCliPath
                                placeholderText: "Auto-detected, or enter path to arduino-cli"
                                color: Colors.textPrimary
                                font.pixelSize: Theme.fontSizeTiny
                                selectByMouse: true
                                onEditingFinished: FirmwareManager.arduinoCliPath = text
                                background: Rectangle { color: Colors.bg3; radius: Theme.radiusSmall; border.color: Colors.border; border.width: 1 }
                            }
                            Text {
                                text: FirmwareManager.boardListStatus
                                color: FirmwareManager.arduinoCliAvailable ? Colors.textSecondary : Colors.warning
                                font.pixelSize: Theme.fontSizeTiny
                                font.family: Theme.fontFamily
                                elide: Text.ElideRight
                                Layout.maximumWidth: 210
                            }
                            IGButton {
                                text: "LOAD BOARDS"
                                implicitWidth: 92
                                implicitHeight: 24
                                secondary: true
                                onClicked: {
                                    if (arduinoCliPathField.text !== FirmwareManager.arduinoCliPath)
                                        FirmwareManager.arduinoCliPath = arduinoCliPathField.text
                                    else
                                        FirmwareManager.refreshBoards()
                                }
                            }
                        }
                    }
                }

                Connections {
                    target: FirmwareManager
                    function onAvailableBoardsChanged() { syncBoardSelection() }
                    function onSelectedBoardChanged() { syncBoardSelection() }
                }

                // Editor header
                Rectangle {
                    Layout.fillWidth: true; height: 28
                    color: Colors.bg2
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                        Text { text: "ARDUINO SKETCH  (.ino)"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                        Item { Layout.fillWidth: true }
                        Text { text: codeEditor.lineCount + " lines"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily }
                    }
                }

                // Code editor
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#0d1117"
                    clip: true

                    // Line numbers
                    Rectangle {
                        id: lineNumPanel
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 44; color: "#0a0e14"
                        Rectangle {
                            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                            width: 1; color: Colors.border
                        }

                        ListView {
                            anchors { fill: parent; topMargin: 8 }
                            model: codeEditor.lineCount
                            clip: true
                            interactive: false
                            // Track the editor's scroll position so line numbers stay
                            // aligned. contentY is a real property write, not a binding,
                            // so it must be driven from the editor's signal.
                            Connections {
                                target: codeEditor
                                function onContentYChanged() { parent.contentY = codeEditor.contentY }
                            }
                            delegate: Text {
                                width: lineNumPanel.width - 8
                                height: 18
                                text: (index + 1)
                                color: Colors.textDisabled
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                horizontalAlignment: Text.AlignRight
                                rightPadding: 6
                            }
                        }
                    }

                    ScrollView {
                        anchors { fill: parent; leftMargin: 44 }
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        TextArea {
                            id: codeEditor
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            color: "#e6edf3"
                            background: Rectangle { color: "transparent" }
                            wrapMode: TextArea.NoWrap
                            selectByMouse: true
                            tabStopDistance: 28
                            leftPadding: 8; topPadding: 8; rightPadding: 8; bottomPadding: 8

                            text: defaultSketch

                            // Syntax highlight hint via color — basic keyword coloring via placeholder
                            placeholderText: "// Paste or type your Arduino sketch here..."
                            placeholderTextColor: Colors.textDisabled
                        }
                    }
                }

                // Action buttons
                Rectangle {
                    Layout.fillWidth: true; height: 48
                    color: Colors.bg1
                    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: Colors.border }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }
                        spacing: Theme.spacingS

                        IGButton {
                            text: FirmwareManager.compiling ? "COMPILING..." : "▶  COMPILE"
                            implicitWidth: 130; implicitHeight: 32
                            enabled: FirmwareManager.arduinoCliAvailable && FirmwareManager.availableBoards.length > 0 && !FirmwareManager.compiling && !FirmwareManager.flashing
                            active: !FirmwareManager.compiling
                            onClicked: FirmwareManager.compileSketch(codeEditor.text)
                        }

                        IGButton {
                            text: FirmwareManager.flashing ? "FLASHING..." : "⚡  FLASH BINARY"
                            implicitWidth: 140; implicitHeight: 32
                            enabled: FirmwareManager.arduinoCliAvailable && !FirmwareManager.flashing && !FirmwareManager.compiling && FirmwareManager.binaryPath !== ""
                            onClicked: FirmwareManager.flashBinary(FirmwareManager.binaryPath, portCombo.currentText)
                        }

                        IGButton {
                            text: "⚡  COMPILE & FLASH"
                            implicitWidth: 160; implicitHeight: 32
                            enabled: FirmwareManager.arduinoCliAvailable && FirmwareManager.availableBoards.length > 0 && !FirmwareManager.compiling && !FirmwareManager.flashing && portCombo.currentText !== ""
                            onClicked: FirmwareManager.compileAndFlash(codeEditor.text, portCombo.currentText)
                        }

                        IGButton {
                            text: "✕  CANCEL"
                            implicitWidth: 90; implicitHeight: 32; danger: true
                            visible: FirmwareManager.compiling || FirmwareManager.flashing
                            onClicked: FirmwareManager.cancelOperation()
                        }

                        Item { Layout.fillWidth: true }

                        IGButton {
                            text: "CLEAR"
                            implicitWidth: 70; implicitHeight: 32; secondary: true
                            onClicked: codeEditor.text = ""
                        }

                        IGButton {
                            text: "TEMPLATE"
                            implicitWidth: 90; implicitHeight: 32; secondary: true
                            onClicked: codeEditor.text = defaultSketch
                        }
                    }
                }
            }

            // Vertical divider
            Rectangle { Layout.fillHeight: true; width: 1; color: Colors.border }

            // ── RIGHT: Status + Logs ─────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Firmware info panel
                Rectangle {
                    Layout.fillWidth: true; height: 110
                    color: Colors.bg2
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spacingM }
                        spacing: 6

                        RowLayout {
                            Text { text: "CONNECTED FIRMWARE"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                            Item { Layout.fillWidth: true }
                            IGButton {
                                text: "REQUEST INFO"; implicitWidth: 110; implicitHeight: 24
                                enabled: vehicle !== null
                                onClicked: { if (vehicle) FirmwareManager.requestFirmwareInfo(vehicle.sysId, vehicle.compId) }
                            }
                        }

                        GridLayout {
                            columns: 4; columnSpacing: Theme.spacingL; rowSpacing: 4
                            Repeater {
                                model: [
                                    ["VERSION",    FirmwareManager.currentVersion || "—"],
                                    ["BOARD",      FirmwareManager.boardType      || "—"],
                                    ["BUILD DATE", FirmwareManager.buildDate      || "—"],
                                    ["BINARY",     FirmwareManager.binaryPath !== "" ? "Ready" : "None"]
                                ]
                                delegate: Row {
                                    spacing: 6
                                    Text { text: modelData[0]+":"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily }
                                    Text { text: modelData[1]; color: Colors.accent; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.bold: true }
                                }
                            }
                        }
                    }
                }

                // Compile progress
                Rectangle {
                    Layout.fillWidth: true; height: 52
                    color: Colors.bg1
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spacingS }
                        spacing: 4

                        RowLayout {
                            Text { text: "COMPILE"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: FirmwareManager.compiling ? "Building..." : (FirmwareManager.compileProgress === 100 ? "✓ Done" : (FirmwareManager.compileProgress === 0 ? "Idle" : "Failed"))
                                color: FirmwareManager.compileProgress === 100 ? Colors.ok : (FirmwareManager.compiling ? Colors.warning : Colors.textDisabled)
                                font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 8; color: Colors.bg3; radius: 4
                            Rectangle {
                                width: parent.width * FirmwareManager.compileProgress / 100
                                height: parent.height; radius: parent.radius
                                color: FirmwareManager.compileProgress === 100 ? Colors.ok : Colors.accent
                                Behavior on width { NumberAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                // Flash progress
                Rectangle {
                    Layout.fillWidth: true; height: 52
                    color: Colors.bg1
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spacingS }
                        spacing: 4

                        RowLayout {
                            Text { text: "FLASH"; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: FirmwareManager.flashing ? "Writing..." : (FirmwareManager.flashProgress === 100 ? "✓ Done" : (FirmwareManager.flashProgress === 0 ? "Idle" : "Failed"))
                                color: FirmwareManager.flashProgress === 100 ? Colors.ok : (FirmwareManager.flashing ? Colors.warning : Colors.textDisabled)
                                font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 8; color: Colors.bg3; radius: 4
                            Rectangle {
                                width: parent.width * FirmwareManager.flashProgress / 100
                                height: parent.height; radius: parent.radius
                                color: FirmwareManager.flashProgress === 100 ? Colors.ok : Colors.accentBlue
                                Behavior on width { NumberAnimation { duration: 100 } }
                            }
                        }
                    }
                }

                // Log tabs
                Rectangle {
                    Layout.fillWidth: true; height: 28
                    color: Colors.bg2
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Colors.border }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 0 }
                        spacing: 0

                        Repeater {
                            model: ["COMPILE LOG", "FLASH LOG"]
                            delegate: Rectangle {
                                height: parent.height
                                width: 110
                                color: logTabs.currentIndex === index ? Colors.bg0 : Colors.bg2
                                border.color: logTabs.currentIndex === index ? Colors.accent : "transparent"
                                border.width: logTabs.currentIndex === index ? 0 : 0
                                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: logTabs.currentIndex === index ? 2 : 0; color: Colors.accent }
                                Text { anchors.centerIn: parent; text: modelData; color: logTabs.currentIndex === index ? Colors.accent : Colors.textSecondary
                                    font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.bold: logTabs.currentIndex === index; font.letterSpacing: 1 }
                                TapHandler { onTapped: logTabs.currentIndex = index }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        IGButton { text: "CLEAR LOG"; implicitWidth: 80; implicitHeight: 22; secondary: true
                            onClicked: { if (logTabs.currentIndex === 0) compileLogView.text = ""; else flashLogView.text = "" } }
                        Item { width: Theme.spacingS }
                    }
                }

                // Log views
                Item {
                    id: logTabs
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property int currentIndex: 0

                    // Compile log
                    ScrollView {
                        anchors.fill: parent
                        visible: logTabs.currentIndex === 0
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        TextArea {
                            id: compileLogView
                            readOnly: true
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            color: Colors.textPrimary
                            background: Rectangle { color: Colors.bg0 }
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            leftPadding: Theme.spacingM; topPadding: Theme.spacingS
                            text: ""
                        }
                    }

                    // Flash log
                    ScrollView {
                        anchors.fill: parent
                        visible: logTabs.currentIndex === 1
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        TextArea {
                            id: flashLogView
                            readOnly: true
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            color: Colors.textPrimary
                            background: Rectangle { color: Colors.bg0 }
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            leftPadding: Theme.spacingM; topPadding: Theme.spacingS
                            text: ""
                        }
                    }
                }

                // ESP32 boot instructions
                Rectangle {
                    Layout.fillWidth: true; height: 56
                    color: Colors.bg2
                    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: Colors.border }

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spacingS }
                        spacing: 2
                        Text { text: "ESP32 BOOT MODE"; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                        Text { text: "If auto-reset fails: hold BOOT → press RESET → release BOOT while upload starts."; color: Colors.textSecondary; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily }
                        Text { text: "COMPILE & FLASH uses Arduino CLI and the selected board's full image layout. Press RESET after upload if needed."; color: Colors.textDisabled; font.pixelSize: Theme.fontSizeTiny; font.family: Theme.fontFamily }
                    }
                }
            }
        }
    }

    // ── Default sketch template ───────────────────────────────────────────────
    readonly property string defaultSketch: `// Indigenous GCS — ESP32 MAVLink Flight Controller Template
// Board: ESP32 Dev Module
// Requires: MAVLink library (install via Arduino Library Manager)

#include <mavlink.h>

#define MAVLINK_SERIAL Serial
#define BAUD_RATE      115200
#define SYS_ID         1
#define COMP_ID        1

uint32_t lastHeartbeat = 0;
float roll = 0, pitch = 0, yaw = 0;
float lat = 28.6139f, lon = 77.2090f, alt = 200.0f;
bool armed = false;

void setup() {
    MAVLINK_SERIAL.begin(BAUD_RATE);
}

void loop() {
    uint32_t now = millis();

    // Send heartbeat at 1 Hz
    if (now - lastHeartbeat >= 1000) {
        lastHeartbeat = now;
        sendHeartbeat();
        sendAttitude();
        sendGlobalPosition();
        sendSysStatus();
    }

    // Read incoming MAVLink
    mavlink_message_t msg;
    mavlink_status_t  status;
    while (MAVLINK_SERIAL.available()) {
        uint8_t c = MAVLINK_SERIAL.read();
        if (mavlink_parse_char(MAVLINK_COMM_0, c, &msg, &status)) {
            handleMessage(msg);
        }
    }
}

void sendHeartbeat() {
    mavlink_message_t msg;
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    uint8_t baseMode = MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
    if (armed) baseMode |= MAV_MODE_FLAG_SAFETY_ARMED;
    mavlink_msg_heartbeat_pack(SYS_ID, COMP_ID, &msg,
        MAV_TYPE_QUADROTOR, MAV_AUTOPILOT_GENERIC,
        baseMode, 0, MAV_STATE_ACTIVE);
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    MAVLINK_SERIAL.write(buf, len);
}

void sendAttitude() {
    mavlink_message_t msg;
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    mavlink_msg_attitude_pack(SYS_ID, COMP_ID, &msg,
        millis(), roll, pitch, yaw, 0, 0, 0);
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    MAVLINK_SERIAL.write(buf, len);
}

void sendGlobalPosition() {
    mavlink_message_t msg;
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    mavlink_msg_global_position_int_pack(SYS_ID, COMP_ID, &msg,
        millis(), (int32_t)(lat*1e7), (int32_t)(lon*1e7),
        (int32_t)(alt*1000), (int32_t)(alt*1000),
        0, 0, 0, 0);
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    MAVLINK_SERIAL.write(buf, len);
}

void sendSysStatus() {
    mavlink_message_t msg;
    uint8_t buf[MAVLINK_MAX_PACKET_LEN];
    mavlink_msg_sys_status_pack(SYS_ID, COMP_ID, &msg,
        0, 0, 0, 500, 12600, -1, 85,
        0, 0, 0, 0, 0, 0, 0, 0, 0);
    uint16_t len = mavlink_msg_to_send_buffer(buf, &msg);
    MAVLINK_SERIAL.write(buf, len);
}

void handleMessage(mavlink_message_t &msg) {
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_COMMAND_LONG: {
            mavlink_command_long_t cmd;
            mavlink_msg_command_long_decode(&msg, &cmd);
            if (cmd.command == MAV_CMD_COMPONENT_ARM_DISARM) {
                armed = (cmd.param1 > 0.5f);
            }
            break;
        }
    }
}
`
}
