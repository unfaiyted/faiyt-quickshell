import QtQuick
import QtQuick.Controls
import "../../../../theme"
import "../../../../services"
import "../.."
import "../../../common"

Item {
    id: aiSettings

    // Format model ID to friendly display name
    function formatModelName(modelId) {
        if (!modelId) return ""
        // claude-sonnet-4-5-20250929 → Claude Sonnet 4.5
        // claude-opus-4-1-20250805 → Claude Opus 4.1
        const parts = modelId.split("-")
        if (parts.length < 3) return modelId

        let name = parts[0].charAt(0).toUpperCase() + parts[0].slice(1) // "Claude"
        let tier = parts[1].charAt(0).toUpperCase() + parts[1].slice(1) // "Sonnet", "Opus", "Haiku"

        // Parse version - could be "4" or "4-5" (meaning 4.5)
        let version = parts[2]
        if (parts.length > 3 && !parts[3].match(/^\d{8}$/)) {
            // parts[3] is not a date, so it's part of the version (e.g., "5" in "4-5")
            version += "." + parts[3]
        }

        return name + " " + tier + " " + version
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        contentHeight: settingsColumn.height
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: settingsColumn
            width: parent.width
            spacing: 16

            // Title
            Text {
                text: "AI Settings"
                font.pixelSize: 16
                font.bold: true
                color: Colors.foreground
            }

            // Claude Settings Section
            Rectangle {
                width: parent.width
                height: claudeSection.height + 16
                radius: 10
                color: Colors.surface

                Column {
                    id: claudeSection
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 12

                    // Section header
                    Row {
                        spacing: 8

                        Text {
                            text: "󰧑"
                            font.family: Fonts.icon
                            font.pixelSize: 16
                            color: Colors.primary
                        }

                        Text {
                            text: "Claude"
                            font.pixelSize: 13
                            font.bold: true
                            color: Colors.foreground
                        }
                    }

                    // API Key Status
                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "API Key"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 6
                            color: ClaudeService.hasApiKey()
                                ? Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.1)
                                : Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.1)
                            border.width: 1
                            border.color: ClaudeService.hasApiKey() ? Colors.success : Colors.error

                            Row {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: ClaudeService.hasApiKey() ? "󰄬" : "󰅜"
                                    font.family: Fonts.icon
                                    font.pixelSize: 14
                                    color: ClaudeService.hasApiKey() ? Colors.success : Colors.error
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: ClaudeService.hasApiKey()
                                        ? "ANTHROPIC_API_KEY is set"
                                        : "ANTHROPIC_API_KEY not found"
                                    font.pixelSize: 11
                                    color: ClaudeService.hasApiKey() ? Colors.success : Colors.error
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Text {
                            text: "Set ANTHROPIC_API_KEY in your shell environment"
                            font.pixelSize: 9
                            color: Colors.foregroundMuted
                        }
                    }

                    // Model
                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "Model"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }

                        Rectangle {
                            id: modelDropdownBtn
                            width: parent.width
                            height: 36
                            radius: 6
                            color: Colors.backgroundAlt

                            HintTarget {
                                targetElement: modelDropdownBtn
                                scope: "sidebar-left"
                                enabled: !modelCombo.popup.visible
                                action: () => modelCombo.popup.open()
                            }

                            ComboBox {
                                id: modelCombo
                                anchors.fill: parent
                                anchors.margins: 2
                                model: ConfigService.aiModels
                                currentIndex: ConfigService.aiModels.indexOf(ConfigService.aiDefaultModel)

                                background: Rectangle {
                                    color: "transparent"
                                }

                                contentItem: Text {
                                    leftPadding: 8
                                    text: formatModelName(ConfigService.aiModels[modelCombo.currentIndex] || "")
                                    font.pixelSize: 11
                                    color: Colors.foreground
                                    verticalAlignment: Text.AlignVCenter
                                }

                                indicator: Text {
                                    x: modelCombo.width - width - 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰅀"
                                    font.family: Fonts.icon
                                    font.pixelSize: 10
                                    color: Colors.foregroundMuted
                                }

                                popup: Popup {
                                    y: modelCombo.height + 2
                                    width: modelCombo.width
                                    padding: 4

                                    background: Rectangle {
                                        color: Colors.surface
                                        radius: 6
                                        border.width: 1
                                        border.color: Colors.border
                                    }

                                    contentItem: ListView {
                                        implicitHeight: contentHeight
                                        model: modelCombo.delegateModel
                                        clip: true
                                    }
                                }

                                delegate: Rectangle {
                                    id: modelDelegate
                                    width: modelCombo.width - 8
                                    height: 32
                                    radius: 4
                                    color: modelDelegateArea.containsMouse ? Colors.overlay : "transparent"

                                    required property int index
                                    required property var modelData

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: formatModelName(modelDelegate.modelData)
                                        font.pixelSize: 11
                                        color: Colors.foreground
                                    }

                                    MouseArea {
                                        id: modelDelegateArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            modelCombo.currentIndex = modelDelegate.index
                                            modelCombo.popup.close()
                                            ConfigService.setValue("ai.defaultModel", modelDelegate.modelData)
                                            ConfigService.saveConfig()
                                            ClaudeService.currentModel = modelDelegate.modelData
                                        }
                                    }

                                    HintTarget {
                                        targetElement: modelDelegate
                                        scope: "sidebar-left"
                                        enabled: modelCombo.popup.visible
                                        action: () => {
                                            modelCombo.currentIndex = modelDelegate.index
                                            modelCombo.popup.close()
                                            ConfigService.setValue("ai.defaultModel", modelDelegate.modelData)
                                            ConfigService.saveConfig()
                                            ClaudeService.currentModel = modelDelegate.modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Temperature
                    Column {
                        width: parent.width
                        spacing: 4

                        Row {
                            width: parent.width

                            Text {
                                text: "Temperature"
                                font.pixelSize: 11
                                color: Colors.foregroundAlt
                            }

                            Item { width: parent.width - 80; height: 1 }

                            Text {
                                text: tempSlider.value.toFixed(1)
                                font.pixelSize: 11
                                color: Colors.foreground
                            }
                        }

                        Slider {
                            id: tempSlider
                            width: parent.width
                            from: 0
                            to: 2
                            stepSize: 0.1
                            value: ConfigService.aiTemperature

                            background: Rectangle {
                                x: tempSlider.leftPadding
                                y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                                width: tempSlider.availableWidth
                                height: 4
                                radius: 2
                                color: Colors.backgroundAlt

                                Rectangle {
                                    width: tempSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 2
                                    color: Colors.primary
                                }
                            }

                            handle: Rectangle {
                                x: tempSlider.leftPadding + tempSlider.visualPosition * (tempSlider.availableWidth - width)
                                y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                                width: 16
                                height: 16
                                radius: 8
                                color: Colors.primary
                            }

                            onValueChanged: {
                                ConfigService.setValue("ai.temperature", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }
            }

            // MCP Servers Section
            Rectangle {
                width: parent.width
                height: mcpSection.height + 16
                radius: 10
                color: Colors.surface

                Column {
                    id: mcpSection
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 12

                    // Section header
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "󰒓"
                            font.family: Fonts.icon
                            font.pixelSize: 16
                            color: Colors.accent
                        }

                        Text {
                            text: "MCP Servers"
                            font.pixelSize: 13
                            font.bold: true
                            color: Colors.foreground
                        }

                        Item { width: parent.width - 150; height: 1 }

                        Text {
                            text: MCPClient.availableTools.length + " tools"
                            font.pixelSize: 10
                            color: Colors.foregroundMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Server list
                    Column {
                        width: parent.width
                        spacing: 4
                        visible: MCPClient.servers.length > 0

                        Repeater {
                            model: MCPClient.servers

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: 6
                                color: Colors.backgroundAlt

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    // Status indicator
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: {
                                            const state = MCPClient.getServerState(modelData.id)
                                            if (state === MCPClient.stateConnected) return Colors.success
                                            if (state === MCPClient.stateConnecting) return Colors.warning
                                            if (state === MCPClient.stateError) return Colors.error
                                            return Colors.foregroundMuted
                                        }
                                    }

                                    // Server name
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 11
                                        color: Colors.foreground
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 80
                                        elide: Text.ElideRight
                                    }

                                    // Toggle
                                    Rectangle {
                                        width: 36
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: modelData.enabled ? Colors.primary : Colors.overlay

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: modelData.enabled ? parent.width - width - 2 : 2
                                            color: Colors.background

                                            Behavior on x { NumberAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            id: toggleArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: MCPClient.toggleServer(modelData.id)
                                        }

                                        HintTarget {
                                            targetElement: parent
                                            scope: "sidebar-left"
                                            action: () => MCPClient.toggleServer(modelData.id)
                                        }
                                    }

                                    // Remove button
                                    Rectangle {
                                        id: removeBtn
                                        width: 20
                                        height: 20
                                        radius: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: removeArea.containsMouse ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.2) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: Fonts.icon
                                            font.pixelSize: 10
                                            color: removeArea.containsMouse ? Colors.error : Colors.foregroundMuted
                                        }

                                        MouseArea {
                                            id: removeArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: MCPClient.removeServer(modelData.id)
                                        }

                                        HintTarget {
                                            targetElement: removeBtn
                                            scope: "sidebar-left"
                                            action: () => MCPClient.removeServer(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        text: "No MCP servers configured"
                        font.pixelSize: 11
                        color: Colors.foregroundMuted
                        visible: MCPClient.servers.length === 0
                    }

                    // Add server button
                    Rectangle {
                        id: addServerBtn
                        width: parent.width
                        height: 36
                        radius: 6
                        color: addServerArea.containsMouse ? Colors.overlay : Colors.backgroundAlt

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰐕"
                                font.family: Fonts.icon
                                font.pixelSize: 12
                                color: Colors.primary
                            }

                            Text {
                                text: "Add MCP Server"
                                font.pixelSize: 11
                                color: Colors.foreground
                            }
                        }

                        MouseArea {
                            id: addServerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addServerDialog.open()
                        }

                        HintTarget {
                            targetElement: addServerBtn
                            scope: "sidebar-left"
                            action: () => addServerDialog.open()
                        }
                    }
                }
            }

            // System Prompt Section
            Rectangle {
                width: parent.width
                height: promptSection.height + 16
                radius: 10
                color: Colors.surface

                Column {
                    id: promptSection
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "System Prompt"
                        font.pixelSize: 13
                        font.bold: true
                        color: Colors.foreground
                    }

                    Rectangle {
                        width: parent.width
                        height: 80
                        radius: 6
                        color: Colors.backgroundAlt
                        border.width: systemPromptInput.activeFocus ? 1 : 0
                        border.color: Colors.primary

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            TextArea {
                                id: systemPromptInput
                                text: ConfigService.aiSystemPrompt
                                placeholderText: "Optional system prompt..."
                                placeholderTextColor: Colors.foregroundMuted
                                font.pixelSize: 11
                                color: Colors.foreground
                                wrapMode: TextEdit.Wrap
                                background: null

                                // Remove focus when hint navigation becomes active
                                Connections {
                                    target: HintNavigationService
                                    function onActiveChanged() {
                                        if (HintNavigationService.active && systemPromptInput.activeFocus) {
                                            systemPromptInput.focus = false
                                        }
                                    }
                                }

                                onTextChanged: {
                                    ConfigService.setValue("ai.systemPrompt", text)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Add Server Dialog
    Popup {
        id: addServerDialog
        anchors.centerIn: parent
        width: 300
        height: 200
        modal: true
        padding: 16

        background: Rectangle {
            color: Colors.background
            radius: 12
            border.width: 1
            border.color: Colors.border
        }

        Column {
            anchors.fill: parent
            spacing: 12

            Text {
                text: "Add MCP Server"
                font.pixelSize: 14
                font.bold: true
                color: Colors.foreground
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Name"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: Colors.surface

                    TextInput {
                        id: serverNameInput
                        anchors.fill: parent
                        anchors.margins: 8
                        font.pixelSize: 11
                        color: Colors.foreground
                        clip: true
                        selectByMouse: true

                        // Remove focus when hint navigation becomes active
                        Connections {
                            target: HintNavigationService
                            function onActiveChanged() {
                                if (HintNavigationService.active && serverNameInput.activeFocus) {
                                    serverNameInput.focus = false
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Command (e.g., npx -y @modelcontextprotocol/server-filesystem /home)"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: Colors.surface

                    TextInput {
                        id: serverCommandInput
                        anchors.fill: parent
                        anchors.margins: 8
                        font.pixelSize: 11
                        color: Colors.foreground
                        clip: true
                        selectByMouse: true

                        // Remove focus when hint navigation becomes active
                        Connections {
                            target: HintNavigationService
                            function onActiveChanged() {
                                if (HintNavigationService.active && serverCommandInput.activeFocus) {
                                    serverCommandInput.focus = false
                                }
                            }
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    id: cancelBtn
                    width: 70
                    height: 32
                    radius: 6
                    color: cancelBtnArea.containsMouse ? Colors.overlay : Colors.surface

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: 11
                        color: Colors.foreground
                    }

                    MouseArea {
                        id: cancelBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addServerDialog.close()
                    }

                    HintTarget {
                        targetElement: cancelBtn
                        scope: "sidebar-left"
                        enabled: addServerDialog.visible
                        action: () => addServerDialog.close()
                    }
                }

                Rectangle {
                    id: addBtn
                    width: 70
                    height: 32
                    radius: 6
                    color: addBtnArea.containsMouse ? Qt.darker(Colors.primary, 1.1) : Colors.primary

                    Text {
                        anchors.centerIn: parent
                        text: "Add"
                        font.pixelSize: 11
                        color: Colors.background
                    }

                    MouseArea {
                        id: addBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (serverNameInput.text && serverCommandInput.text) {
                                const command = serverCommandInput.text.split(" ")
                                MCPClient.addServer(serverNameInput.text, command, {})
                                serverNameInput.text = ""
                                serverCommandInput.text = ""
                                addServerDialog.close()
                            }
                        }
                    }

                    HintTarget {
                        targetElement: addBtn
                        scope: "sidebar-left"
                        enabled: addServerDialog.visible
                        action: () => {
                            if (serverNameInput.text && serverCommandInput.text) {
                                const command = serverCommandInput.text.split(" ")
                                MCPClient.addServer(serverNameInput.text, command, {})
                                serverNameInput.text = ""
                                serverCommandInput.text = ""
                                addServerDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
