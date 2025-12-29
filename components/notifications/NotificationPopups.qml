pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "."

PanelWindow {
    id: root

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "notification_popups"
    color: "transparent"

    anchors.right: true
    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    // Only capture input in the content area
    mask: Region {
        item: content
    }

    Item {
        id: content

        // Reverse notifications so newest is first
        property var notifications: [...NotificationState.notifications].reverse()

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 44  // Below bar
        anchors.rightMargin: 12

        implicitWidth: childrenRect.width
        implicitHeight: notifications.length > 0 ? childrenRect.height : 0
        clip: true

        ListView {
            id: list
            interactive: false
            clip: true

            // Stacked when inactive, spaced when hovered
            spacing: list.isActivated ? 10 : -100

            implicitWidth: 380

            // Calculate height from children
            onCountChanged: {
                var root = list.visibleChildren[0]
                var listViewHeight = 0

                if (root) {
                    for (var i = 0; i < root.visibleChildren.length; i++) {
                        listViewHeight += root.visibleChildren[i].height
                    }
                }

                list.height = listViewHeight + (list.isActivated ? (count - 1) * 10 : 0)
            }

            model: ScriptModel {
                values: content.notifications
            }

            property bool isActivated: false

            // Animation for items moving
            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            // Animation for items being removed
            remove: Transition {
                SequentialAnimation {
                    PropertyAction {
                        property: "z"
                        value: 0
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 200
                        }
                        NumberAnimation {
                            property: "scale"
                            to: 0.5
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Animation for items being added
            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "y"
                        from: -20
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                    }
                }
            }

            delegate: NotificationItem {
                required property var modelData
                required property int index

                notif: modelData
                notifIndex: index
                isActivated: list.isActivated
            }

            // Hover detection to toggle activation
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true

                onEntered: {
                    list.isActivated = true
                }
                onExited: {
                    list.isActivated = false
                }

                preventStealing: true
                onClicked: e => { e.accepted = false }
                onPressed: e => { e.accepted = false }
            }

            // Smooth spacing animation
            Behavior on spacing {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
