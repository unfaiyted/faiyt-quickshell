import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../../theme"

Item {
    id: toolsModule

    property string selectedCategory: "all"
    property string searchQuery: ""

    // Tool definitions
    property var tools: [
        { id: "git-status", name: "Git Status", icon: "󰊢", description: "Check git status of current project", category: "development" },
        { id: "docker-status", name: "Docker Status", icon: "󰡨", description: "View running Docker containers", category: "development" },
        { id: "port-scanner", name: "Port Scanner", icon: "󰒍", description: "Check common development ports", category: "network" },
        { id: "clear-cache", name: "Clear Cache", icon: "󰆴", description: "Clear system caches", category: "system" },
        { id: "system-info", name: "System Info", icon: "󰋼", description: "View system information", category: "monitoring" },
        { id: "process-monitor", name: "Process Monitor", icon: "󰍛", description: "View top CPU/Memory processes", category: "monitoring" },
        { id: "dns-flush", name: "DNS Flush", icon: "󰇚", description: "Flush DNS cache", category: "network" },
        { id: "node-version", name: "Node Version", icon: "󰎙", description: "Check Node.js and npm versions", category: "development" },
        { id: "disk-usage", name: "Disk Usage", icon: "󰋊", description: "Check disk space usage", category: "monitoring" },
        { id: "network-info", name: "Network Info", icon: "󰛳", description: "View network interfaces", category: "network" }
    ]

    property var categories: [
        { id: "all", name: "All", icon: "󰕰" },
        { id: "development", name: "Dev", icon: "󰅩" },
        { id: "system", name: "System", icon: "󰒓" },
        { id: "network", name: "Network", icon: "󰛳" },
        { id: "monitoring", name: "Monitor", icon: "󰄪" }
    ]

    // Filter tools based on search and category
    function getFilteredTools() {
        return tools.filter(function(tool) {
            let matchesCategory = selectedCategory === "all" || tool.category === selectedCategory
            let matchesSearch = searchQuery === "" ||
                tool.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                tool.description.toLowerCase().includes(searchQuery.toLowerCase())
            return matchesCategory && matchesSearch
        })
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Search bar
        Rectangle {
            width: parent.width
            height: 40
            radius: 10
            color: Colors.surface

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: "󰍉"
                    font.family: Fonts.icon
                    font.pixelSize: 16
                    color: Colors.foregroundMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 13
                    color: Colors.foreground
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Search tools..."
                        font.pixelSize: 13
                        color: Colors.foregroundMuted
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    onTextChanged: toolsModule.searchQuery = text
                }
            }
        }

        // Category tabs
        Row {
            width: parent.width
            spacing: 6

            Repeater {
                model: categories

                Rectangle {
                    width: (parent.width - 24) / 5
                    height: 32
                    radius: 8
                    color: selectedCategory === modelData.id ? Colors.primary : Colors.surface

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: modelData.icon
                            font.family: Fonts.icon
                            font.pixelSize: 12
                            color: selectedCategory === modelData.id ? Colors.background : Colors.foreground
                        }

                        Text {
                            text: modelData.name
                            font.pixelSize: 10
                            color: selectedCategory === modelData.id ? Colors.background : Colors.foreground
                            visible: parent.width > 50
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toolsModule.selectedCategory = modelData.id
                    }
                }
            }
        }

        // Tools list
        Flickable {
            width: parent.width
            height: parent.height - 100
            clip: true
            contentHeight: toolsColumn.height
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: toolsColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: getFilteredTools()

                    ToolItem {
                        width: toolsColumn.width
                        toolId: modelData.id
                        toolName: modelData.name
                        toolIcon: modelData.icon
                        toolDescription: modelData.description
                    }
                }

                // Empty state
                Item {
                    width: parent.width
                    height: 120
                    visible: getFilteredTools().length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰍉"
                            font.family: Fonts.icon
                            font.pixelSize: 32
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No tools found"
                            font.pixelSize: 12
                            color: Colors.foregroundMuted
                        }
                    }
                }
            }
        }
    }
}
