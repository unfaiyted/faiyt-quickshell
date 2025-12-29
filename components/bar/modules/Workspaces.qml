import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../theme"
import ".."

Rectangle {
    id: workspacesContainer

    color: Colors.backgroundElevated
    radius: 16
    implicitWidth: row.width + 12
    implicitHeight: 30

    // Track which workspace tooltip is open (-1 = none)
    property int openTooltipId: -1

    // Helper function to check if workspace is occupied
    function isWorkspaceOccupied(wsId) {
        for (let ws of Hyprland.workspaces.values) {
            if (ws.id === wsId) {
                return true;
            }
        }
        return false;
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: 10

            Rectangle {
                id: wsIndicator
                width: 22
                height: 22
                radius: 12

                required property int index
                property int wsId: index + 1
                property bool isActive: Hyprland.focusedWorkspace
                    ? Hyprland.focusedWorkspace.id === wsId
                    : false
                property bool isOccupied: workspacesContainer.isWorkspaceOccupied(wsId)
                property bool tooltipOpen: workspacesContainer.openTooltipId === wsId

                color: isActive ? Colors.rose
                     : isOccupied ? Colors.surface
                     : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: wsIndicator.wsId
                    font.pixelSize: 10
                    color: wsIndicator.isActive ? Colors.base
                         : wsIndicator.isOccupied ? Colors.foreground
                         : Colors.subtle
                }

                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Hyprland.dispatch("workspace " + wsIndicator.wsId)

                    onEntered: {
                        if (wsIndicator.isOccupied) {
                            workspacesContainer.openTooltipId = wsIndicator.wsId
                        }
                    }

                    onExited: {
                        // Start close timer - tooltip can cancel it if mouse enters it
                        if (wsIndicator.tooltipOpen) {
                            tooltipContent.startCloseTimer()
                        }
                    }
                }

                // Tooltip for each workspace indicator
                PopupWindow {
                    id: wsTooltip
                    anchor.window: QsWindow.window
                    anchor.onAnchoring: {
                        const pos = wsIndicator.mapToItem(QsWindow.window.contentItem, 0, wsIndicator.height)
                        anchor.rect = Qt.rect(pos.x, pos.y, wsIndicator.width, 7)
                    }
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom

                    visible: wsIndicator.tooltipOpen

                    implicitWidth: tooltipContent.width
                    implicitHeight: tooltipContent.height
                    color: "transparent"

                    WorkspaceTooltip {
                        id: tooltipContent
                        workspaceId: wsIndicator.wsId
                        isVisible: wsTooltip.visible

                        onRequestClose: {
                            workspacesContainer.openTooltipId = -1
                        }

                        onCancelClose: {
                            // Mouse entered tooltip, keep it open
                        }
                    }
                }
            }
        }
    }
}
