pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "."

PanelWindow {
    id: root

    visible: ConfigService.windowNotificationsEnabled
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

        // Reverse notifications so newest is first. Ones whose image has not
        // resolved yet are held back so they never appear then resize.
        property var notifications: [...NotificationState.notifications]
            .reverse()
            .filter(n => n && n.ready)

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 44  // Below bar
        anchors.rightMargin: 12

        implicitWidth: 380
        implicitHeight: notifications.length > 0 ? stack.height : 0

        // A Column rather than a ListView: cards resize after they appear (an
        // image finishing its decode, a body rewrapping), and ListView keeps the
        // delegate sizes it measured at creation - it left contentHeight and
        // every item position stale, clipping taller cards. forceLayout() does
        // not recover it. A Column re-stacks on any child resize, and with at
        // most a handful of popups there is nothing to virtualize.
        Column {
            id: stack
            width: parent.width

            // Idle: cards collapse into a tight stack showing only a sliver of
            // each card behind. Hover: they fan apart.
            readonly property int stackPeek: 10
            readonly property int fanSpacing: 10

            property bool isActivated: false

            // Cards behind shrink themselves to a stackPeek strip when
            // collapsed, so plain zero spacing tiles them exactly.
            spacing: stack.isActivated ? stack.fanSpacing : 0

            Behavior on spacing {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            // A HoverHandler coexists with the cards' own MouseAreas, unlike the
            // full-area MouseArea this replaced, which had to forward every
            // press to let buttons underneath work.
            HoverHandler {
                id: stackHover
                onHoveredChanged: stack.isActivated = hovered
            }

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            add: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: ScriptModel {
                    values: content.notifications
                }

                delegate: NotificationItem {
                    required property var modelData
                    required property int index

                    width: stack.width
                    notif: modelData
                    notifIndex: index
                    isActivated: stack.isActivated
                    stackPeek: stack.stackPeek
                }
            }
        }
    }
}
