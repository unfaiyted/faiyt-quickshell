import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../common"

Item {
    id: collapsibleSection

    property string title: ""
    property string icon: ""
    property bool expanded: false
    property string hintScope: "settings"
    default property alias content: contentColumn.children

    width: parent.width
    implicitHeight: headerRow.height + (expanded ? contentContainer.height : 0)
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Header row
    Rectangle {
        id: headerRow
        width: parent.width
        height: 36
        radius: 8
        color: headerArea.containsMouse
            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
        border.width: 1
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.08)

        Behavior on color { ColorAnimation { duration: 150 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // Chevron icon
            Text {
                text: ""
                font.family: Fonts.icon
                font.pixelSize: 12
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
                rotation: collapsibleSection.expanded ? 90 : 0

                Behavior on rotation {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }

            // Optional section icon
            Text {
                visible: collapsibleSection.icon !== ""
                text: collapsibleSection.icon
                font.family: Fonts.icon
                font.pixelSize: 14
                color: Colors.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            // Title
            Text {
                text: collapsibleSection.title
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Colors.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: collapsibleSection.expanded = !collapsibleSection.expanded
        }

        HintTarget {
            targetElement: headerRow
            scope: collapsibleSection.hintScope
            action: () => collapsibleSection.expanded = !collapsibleSection.expanded
        }
    }

    // Content container
    Item {
        id: contentContainer
        anchors.top: headerRow.bottom
        anchors.topMargin: 8
        width: parent.width
        height: contentColumn.height
        // Keep visible during animation, hide when fully collapsed
        visible: collapsibleSection.expanded || opacityAnim.running
        opacity: collapsibleSection.expanded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                id: opacityAnim
                duration: 150
            }
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: 4
            leftPadding: 12
            rightPadding: 12
            bottomPadding: 8
        }
    }
}
