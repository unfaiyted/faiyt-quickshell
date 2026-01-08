import QtQuick
import "../../../../theme"
import "../../../../services"
import "../../../common"

Item {
    id: tabBar

    property var tabData: []  // [{icon, label}]
    property int currentIndex: 0
    signal tabClicked(int index)

    implicitHeight: 44
    implicitWidth: parent.width

    // Container with subtle background
    Rectangle {
        id: container
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        radius: 10
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)

        Row {
            id: tabRow
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: tabBar.tabData.length

                Rectangle {
                    id: tabButton

                    property bool isActive: tabBar.currentIndex === index
                    property bool isHovered: false

                    width: tabContent.width + 12
                    height: 32
                    radius: 6

                    color: isActive
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                        : isHovered
                            ? Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.5)
                            : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    Row {
                        id: tabContent
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            id: tabIcon
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabBar.tabData[index] ? tabBar.tabData[index].icon : ""
                            color: tabButton.isActive ? Colors.primary : Colors.foregroundAlt
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconSmall

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }
                        }

                        Text {
                            id: tabLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabBar.tabData[index] ? tabBar.tabData[index].label : ""
                            color: tabButton.isActive ? Colors.primary : Colors.foregroundAlt
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.tiny
                            font.weight: tabButton.isActive ? Font.DemiBold : Font.Normal
                            visible: tabBar.tabData.length <= 5  // Hide labels if too many tabs

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            tabBar.currentIndex = index
                            tabBar.tabClicked(index)
                        }
                        onEntered: tabButton.isHovered = true
                        onExited: tabButton.isHovered = false
                    }

                    HintTarget {
                        targetElement: tabButton
                        scope: "sidebar-left"
                        action: () => {
                            tabBar.currentIndex = index
                            tabBar.tabClicked(index)
                        }
                    }
                }
            }
        }
    }
}
