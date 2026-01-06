import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services" as Services

Scope {
    id: indicatorScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: indicatorWindow

            property var modelData
            screen: modelData

            anchors {
                bottom: true
                left: true
                right: true
            }

            implicitHeight: 150
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0

            // Only show on primary screen
            visible: (modelData === Quickshell.screens[0]) && (IndicatorState.visible || fadeAnimation.running)

            // Click-through: no mask means no input
            mask: Region {}

            Item {
                id: content
                anchors.fill: parent

                // Centered card at bottom
                Item {
                    id: cardContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40

                    width: 280
                    height: 80

                    opacity: IndicatorState.visible ? 1 : 0
                    scale: IndicatorState.visible ? 1 : 0.9

                    Behavior on opacity {
                        NumberAnimation {
                            id: fadeAnimation
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Volume indicator
                    Loader {
                        anchors.fill: parent
                        active: IndicatorState.activeIndicator === "volume"
                        sourceComponent: IndicatorCard {
                            icon: IndicatorState.getVolumeIcon()
                            value: IndicatorState.volumeValue
                            label: IndicatorState.volumeMuted ? "Muted" : ""
                        }
                    }

                    // Brightness indicator
                    Loader {
                        anchors.fill: parent
                        active: IndicatorState.activeIndicator === "brightness"
                        sourceComponent: IndicatorCard {
                            icon: IndicatorState.getBrightnessIcon()
                            value: IndicatorState.brightnessValue
                            label: "Display Brightness"
                        }
                    }

                    // Keyboard backlight indicator
                    Loader {
                        anchors.fill: parent
                        active: IndicatorState.activeIndicator === "keyboard"
                        sourceComponent: IndicatorCard {
                            icon: IndicatorState.getKeyboardIcon()
                            value: IndicatorState.kbBrightnessValue
                            label: "Keyboard Backlight"
                        }
                    }
                }
            }
        }
    }
}
