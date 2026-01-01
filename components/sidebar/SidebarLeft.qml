import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "modules"
import "modules/ai"

PanelWindow {
    id: leftSidebar

    anchors {
        top: true
        bottom: true
        left: true
    }

    property bool expanded: SidebarState.leftOpen

    // Fixed width - includes padding space
    implicitWidth: 475  // ~20% wider than original 396
    margins.top: 0     // Below the bar
    exclusiveZone: 0
    color: "transparent"

    // Keyboard focus for Escape key
    WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Hide window when not expanded (after animation completes)
    visible: expanded || slideAnimation.running || bgFadeAnim.running

    // Dark background to match overlay (curved top-left to avoid bar corner)
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        opacity: leftSidebar.expanded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                id: bgFadeAnim
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width
            var h = height
            var r = 24  // Match bar corner radius

            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.3)
            ctx.beginPath()
            ctx.moveTo(0, r)
            ctx.arc(r, r, r, Math.PI, -Math.PI / 2, false)
            ctx.lineTo(w, 0)
            ctx.lineTo(w, h)
            ctx.lineTo(0, h)
            ctx.lineTo(0, r)
            ctx.closePath()
            ctx.fill()
        }

        Component.onCompleted: requestPaint()
    }

    // Clip container for smooth slide animation
    Item {
        anchors.fill: parent
        anchors.margins: 8  // Internal padding
        clip: true

        // Sliding content panel
        Rectangle {
            id: contentPanel
            width: parent.width
            height: parent.height
            radius: 16
            color: Colors.background

            // Slide from left: -width (hidden) to 0 (visible)
            x: leftSidebar.expanded ? 0 : -width

            Behavior on x {
                NumberAnimation {
                    id: slideAnimation
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Content with fade
            Item {
                anchors.fill: parent
                opacity: leftSidebar.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                Column {
                    anchors.fill: parent
                    spacing: 0

                    // Dynamic Header based on active tab
                    Item {
                        width: parent.width
                        height: 56

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Text {
                                text: AIState.activeMainTab === 0 ? "󰚩" : "󰦖"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 24
                                color: Colors.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: AIState.activeMainTab === 0 ? "AI Chat" : "Tools"
                                font.pixelSize: 18
                                font.bold: true
                                color: Colors.foreground
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Colors.border
                        }
                    }

                    // Tab bar
                    LeftTabBar {
                        id: mainTabBar
                        width: parent.width
                        tabData: [
                            { icon: "󰚩", label: "AI" },
                            { icon: "󰦖", label: "Tools" }
                        ]
                        currentIndex: AIState.activeMainTab
                        onTabClicked: index => AIState.activeMainTab = index
                    }

                    // Tab content
                    Loader {
                        width: parent.width
                        height: parent.height - 56 - mainTabBar.height
                        sourceComponent: AIState.activeMainTab === 0 ? aiPanelComponent : toolsComponent
                    }

                    Component {
                        id: aiPanelComponent
                        AIPanel {}
                    }

                    Component {
                        id: toolsComponent
                        Tools {}
                    }
                }
            }

            // Subtle border
            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "transparent"
                border.width: 1
                border.color: Colors.border
            }
        }
    }

    // Keyboard handler for Escape (at window level for reliable focus)
    FocusScope {
        anchors.fill: parent
        focus: leftSidebar.expanded

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                SidebarState.leftOpen = false
                event.accepted = true
            }
        }
    }
}
