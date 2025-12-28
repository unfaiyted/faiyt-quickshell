import QtQuick
import Quickshell.Hyprland
import "../theme"

Rectangle {
    id: workspacesContainer

    color: Colors.backgroundElevated
    radius: 16
    implicitWidth: row.width + 16
    implicitHeight: 32

    // Helper function to check if workspace is occupied
    function isWorkspaceOccupied(wsId) {
        for (let i = 0; i < Hyprland.workspaces.length; i++) {
            let ws = Hyprland.workspaces[i];
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
                width: 24
                height: 24
                radius: 12

                required property int index
                property int wsId: index + 1
                property bool isActive: Hyprland.focusedWorkspace
                    ? Hyprland.focusedWorkspace.id === wsId
                    : false
                property bool isOccupied: workspacesContainer.isWorkspaceOccupied(wsId)

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
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsIndicator.wsId)
                }
            }
        }
    }
}
