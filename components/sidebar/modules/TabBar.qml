import QtQuick
import "../../../theme"
import "../../../services"
import "../../common"

Item {
    id: tabBar

    property var tabs: []
    property int currentIndex: 0

    // Tab data with icons and labels
    readonly property var tabData: [
        { icon: "󰂚", label: "Alerts" },
        { icon: "󰕾", label: "Audio" },
        { icon: "󰂯", label: "BT" },
        { icon: "󰤨", label: "WiFi" },
        { icon: "󰃭", label: "Cal" }
    ]

    implicitHeight: 52
    implicitWidth: parent.width

    // Container with elevated background
    Rectangle {
        id: container
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        radius: 12
        color: Colors.backgroundElevated
        border.width: 1
        border.color: Colors.border

        // Inner container for the tab buttons
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.6)

            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: tabBar.tabs.length

                    Rectangle {
                        id: tabButton

                        property bool isActive: tabBar.currentIndex === index
                        property bool isHovered: false

                        width: tabContent.width + 14
                        height: 36
                        radius: 8

                        // Semi-transparent background - unselected tabs have subtle surface color
                        color: isActive
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                            : isHovered
                                ? Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.8)
                                : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)

                        border.width: isActive ? 1 : 0
                        border.color: isActive
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
                            : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }

                        Row {
                            id: tabContent
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                id: tabIcon
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabBar.tabData[index] ? tabBar.tabData[index].icon : tabBar.tabs[index]
                                color: tabButton.isActive ? Colors.accent : Colors.foregroundAlt
                                font.family: Fonts.icon
                                font.pixelSize: 13

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            Text {
                                id: tabLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabBar.tabData[index] ? tabBar.tabData[index].label : ""
                                color: tabButton.isActive ? Colors.accent : Colors.foregroundAlt
                                font.pixelSize: 10
                                font.weight: tabButton.isActive ? Font.DemiBold : Font.Normal

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: tabBar.currentIndex = index
                            onEntered: tabButton.isHovered = true
                            onExited: tabButton.isHovered = false
                        }

                        // Hint navigation target
                        HintTarget {
                            targetElement: tabButton
                            scope: "sidebar-right"
                            action: () => { tabBar.currentIndex = index }
                        }
                    }
                }
            }
        }
    }
}
