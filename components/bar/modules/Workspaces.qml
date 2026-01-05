import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../theme"
import "../../../services"
import ".."
import "../../common"

Rectangle {
    id: workspacesContainer

    color: Colors.backgroundElevated
    radius: 16
    implicitWidth: row.width + 12
    implicitHeight: 30

    // Track which workspace tooltip is open (-1 = none)
    property int openTooltipId: -1

    // Listen for popup scope cleared signal to close tooltip
    Connections {
        target: HintNavigationService
        function onPopupScopeCleared(scope) {
            if (scope === "workspace-popup") {
                workspacesContainer.openTooltipId = -1
            }
        }
    }

    // Paged workspaces configuration
    property int perPage: ConfigService.workspacesPerPage
    property int currentPage: {
        // Calculate page based on focused workspace
        const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
        return Math.floor((focusedId - 1) / perPage)
    }
    property int pageStart: currentPage * perPage + 1  // First workspace ID on current page

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
            model: workspacesContainer.perPage

            Rectangle {
                id: wsIndicator
                width: 24
                height: 24
                radius: 12

                required property int index
                // Calculate workspace ID based on current page
                property int wsId: workspacesContainer.pageStart + index
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
                    font.pixelSize: 12
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

                HintTarget {
                    targetElement: wsIndicator
                    scope: "bar"
                    action: () => Hyprland.dispatch("workspace " + wsIndicator.wsId)
                    secondaryAction: () => {
                        // Shift+key opens the workspace tooltip/popup
                        if (wsIndicator.isOccupied) {
                            workspacesContainer.openTooltipId = wsIndicator.wsId
                            HintNavigationService.setPopupScope("workspace-popup")
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
                            HintNavigationService.clearPopupScope()
                        }

                        onCancelClose: {
                            // Mouse entered tooltip, keep it open
                        }
                    }

                    // Hint overlay directly in tooltip (no nested PopupWindow)
                    HintOverlay {
                        id: wsHintOverlay
                        anchors.fill: tooltipContent
                        scope: "workspace-popup"
                        z: 1000
                    }

                    // Keyboard handling for hints in popup
                    FocusScope {
                        id: popupKeyHandler
                        anchors.fill: parent
                        focus: wsTooltip.visible && HintNavigationService.active

                        Keys.onPressed: function(event) {
                            // Escape closes the popup
                            if (event.key === Qt.Key_Escape) {
                                workspacesContainer.openTooltipId = -1
                                HintNavigationService.clearPopupScope()
                                event.accepted = true
                                return
                            }

                            if (HintNavigationService.active) {
                                let key = ""
                                if (event.key === Qt.Key_Backspace) key = "Backspace"
                                else if (event.text && event.text.length === 1) key = event.text

                                if (key && HintNavigationService.handleKey(key, "workspace-popup", event.modifiers)) {
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
