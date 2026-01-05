import QtQuick
import "../../services"
import "../../theme"

Item {
    id: hintOverlay

    // Container with hinted elements
    property Item targetRoot: parent

    // Filter to only show hints for this scope
    property string scope: ""

    // Hint badge anchor position: "topLeft" (default) or "bottomCenter"
    property string anchorPosition: "topLeft"

    // Optional: Item to use for coordinate mapping (for cross-window hints)
    property Item mapRoot: null

    // Make overlay fill parent and sit on top
    anchors.fill: parent
    z: 1000

    // Only visible when hint mode is active
    visible: HintNavigationService.active

    // Fade in/out animation
    opacity: HintNavigationService.active ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // Computed filtered targets - explicitly depend on targets array and input buffer
    property var filteredTargets: {
        const allTargets = HintNavigationService.targets
        const isActive = HintNavigationService.active
        const input = HintNavigationService.inputBuffer.toLowerCase()
        if (!isActive || !allTargets) return []

        // Filter by scope, visibility, non-empty hint, and matching prefix
        return allTargets.filter(t => {
            if (t.scope !== hintOverlay.scope) return false
            if (!t.element || !t.element.visible) return false
            if (!t.hint || t.hint === "") return false
            // If user is typing, only show matching hints
            if (input !== "" && !t.hint.startsWith(input)) return false
            return true
        })
    }

    // Hint badges
    Repeater {
        id: hintRepeater
        model: hintOverlay.filteredTargets

        delegate: Rectangle {
            id: hintBadge

            property var target: modelData
            property string inputBuffer: HintNavigationService.inputBuffer.toLowerCase()
            property string hint: target.hint || ""
            property bool isExact: hint === inputBuffer

            property point pos: {
                if (!target || !target.element) return Qt.point(0, 0)
                // Use mapRoot if provided (for cross-window mapping), otherwise use hintOverlay
                let mapTarget = hintOverlay.mapRoot || hintOverlay
                return target.element.mapToItem(mapTarget, 0, 0)
            }

            property real targetWidth: target && target.element ? target.element.width : 0
            property real targetHeight: target && target.element ? target.element.height : 0

            // Position based on anchor mode
            x: hintOverlay.anchorPosition === "bottomCenter"
                ? pos.x + (targetWidth / 2) - (width / 2)
                : pos.x - 6
            y: hintOverlay.anchorPosition === "bottomCenter"
                ? pos.y + targetHeight + 2
                : pos.y - 6

            width: hintTextRow.width + 10
            height: 18
            radius: 4

            // Theme-matched colors
            color: Colors.rose
            border.width: 1
            border.color: Qt.darker(color, 1.15)

            scale: isExact ? 1.1 : 1.0

            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutBack } }

            // Row to show matched prefix (muted) and remaining chars (bold)
            Row {
                id: hintTextRow
                anchors.centerIn: parent
                spacing: 0

                // Matched prefix (muted) - what user has typed
                Text {
                    id: matchedText
                    text: inputBuffer.length > 0 ? hint.substring(0, inputBuffer.length).toUpperCase() : ""
                    font.pixelSize: 11
                    font.bold: false
                    font.family: "monospace"
                    color: Qt.darker(Colors.base, 1.4)  // Muted color
                    visible: inputBuffer.length > 0
                }

                // Remaining chars (highlighted) - what user still needs to type
                Text {
                    id: remainingText
                    text: {
                        if (inputBuffer.length > 0) {
                            return hint.substring(inputBuffer.length).toUpperCase()
                        }
                        return hint.toUpperCase()
                    }
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "monospace"
                    color: Colors.base
                }
            }
        }
    }

    // Input buffer display (optional - shows what user has typed)
    Rectangle {
        id: inputDisplay
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8

        visible: HintNavigationService.inputBuffer.length > 0
        width: inputText.width + 20
        height: 28
        radius: 6
        color: Colors.surface
        border.width: 1
        border.color: Colors.primary

        Text {
            id: inputText
            anchors.centerIn: parent
            text: HintNavigationService.inputBuffer.toUpperCase()
            font.pixelSize: 14
            font.bold: true
            font.family: "monospace"
            color: Colors.primary
        }
    }
}
