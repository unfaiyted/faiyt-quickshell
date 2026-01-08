import QtQuick
import "../../theme"
import "../../services"
import "../common"

Rectangle {
    id: resultItem

    property var result: null
    property bool isSelected: false

    signal clicked()
    signal contextMenu(var result)

    height: 52
    radius: 10
    color: isSelected ? Colors.overlay : (itemArea.containsMouse ? Colors.surface : "transparent")
    border.width: isSelected ? 1 : 0
    border.color: Colors.primary

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Icon container
        Rectangle {
            width: 32
            height: 32
            radius: 8
            color: Colors.surface
            anchors.verticalCenter: parent.verticalCenter

            // Favicon image (for bookmarks)
            Image {
                id: faviconImage
                anchors.centerIn: parent
                width: 18
                height: 18
                source: result?.iconImage ? "file://" + result.iconImage : ""
                visible: status === Image.Ready
                asynchronous: true
                smooth: true
                mipmap: true
            }

            // NerdFont icon fallback
            Text {
                anchors.centerIn: parent
                text: result ? (result.icon || "󰀻") : "󰀻"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconLarge
                color: isSelected ? Colors.primary : Colors.foreground
                visible: !faviconImage.visible
            }
        }

        // Text content
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 56
            spacing: 2

            // Title
            Text {
                width: parent.width
                text: result ? (result.title || "") : ""
                font.family: Fonts.ui
                font.pixelSize: Fonts.medium
                font.bold: isSelected
                color: Colors.foreground
                elide: Text.ElideRight
            }

            // Description
            Text {
                width: parent.width
                text: result ? (result.description || "") : ""
                font.family: Fonts.ui
                font.pixelSize: Fonts.small
                color: Colors.foregroundAlt
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }

    // Type badge (optional)
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: typeBadgeText.width + 12
        height: 20
        radius: 4
        color: Colors.surface
        visible: result && result.type && result.type !== "app"

        Text {
            id: typeBadgeText
            anchors.centerIn: parent
            text: result ? (result.type || "") : ""
            font.family: Fonts.ui
            font.pixelSize: Fonts.tiny
            font.bold: true
            color: Colors.foregroundMuted
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                resultItem.contextMenu(result)
            } else {
                resultItem.clicked()
            }
        }
    }

    HintTarget {
        targetElement: resultItem
        scope: "launcher"
        enabled: LauncherState.visible
        action: () => {
            HintNavigationService.deactivate()
            resultItem.clicked()
        }
        secondaryAction: () => {
            resultItem.contextMenu(result)
        }
    }
}
