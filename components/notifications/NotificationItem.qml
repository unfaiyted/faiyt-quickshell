pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../../theme"
import "../../services"
import "."

Item {
    id: root

    required property var notif
    required property int notifIndex
    required property bool isActivated

    // Height of the strip each card behind collapses to
    property int stackPeek: 10

    // Check if this is a critical notification
    readonly property bool isCritical: root.notif?.urgency === NotificationUrgency.Critical

    // Normalized image hint. Apps send both avatars/album art and screenshots
    // through this one hint, so the shape decides how it is laid out.
    readonly property string imageSource: root.notif?.imageSource ?? ""

    // Actions to draw as buttons, minus the click-activation "default" action
    readonly property var buttonActions: NotificationState.displayActions(root.notif?.actions)

    // The spec's "default" action is what a click on the notification body runs
    readonly property var defaultAction: {
        const acts = root.notif?.actions ?? []
        for (let i = 0; i < acts.length; i++) {
            if (acts[i] && acts[i].identifier === "default") return acts[i]
        }
        return null
    }

    // Clicking the card runs the sender's default action when there is one,
    // then focuses the app that sent it and clears the popup.
    function activate() {
        const appName = root.notif?.appName ?? ""
        if (root.defaultAction) root.defaultAction.invoke()
        NotificationState.focusAppWindow(appName)
        if (root.notif) root.notif.remove()
    }

    // Resolved before the popup was ever shown, so the card is laid out
    // correctly on its first frame instead of resizing a beat later.
    readonly property real imageAspect: root.notif?.imageAspect ?? 0
    readonly property bool imageProbed: imageAspect > 0
    // Square-ish means icon/avatar/album art -> small thumbnail beside the text.
    // Anything clearly wider or taller is a real picture -> full-width preview.
    readonly property bool imageIsThumbnail: imageProbed && imageAspect > 0.8 && imageAspect < 1.25

    // Height the wide preview occupies, known up front from the pre-resolved
    // aspect, so the card never grows after it appears.
    readonly property real previewHeight: {
        if (!imageProbed || imageIsThumbnail) return 0
        const w = Math.max(1, width - 24)
        return Math.min(w / imageAspect, 140)
    }

    // Collapsed, only the newest card is laid out at full height; the ones
    // behind occupy a fixed strip and clip to it. That keeps every sliver the
    // same regardless of how tall the individual notifications are - a uniform
    // ListView spacing cannot, since the gap between card tops is always
    // (previous card height + spacing).
    implicitHeight: (isActivated || notifIndex === 0) ? card.height : stackPeek
    implicitWidth: parent?.width ?? 380


    // Stack cards with z-index
    z: 100 - notifIndex

    // Enter and exit animations, previously supplied by the ListView's add and
    // remove transitions. Driven by notif.removing so the card fades before it
    // is actually dropped from the list.
    property bool appeared: false
    readonly property bool leaving: root.notif?.removing ?? false

    opacity: (!appeared || leaving) ? 0 : 1
    scale: leaving ? 0.92 : 1

    Component.onCompleted: appeared = true

    Behavior on opacity {
        NumberAnimation {
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

    // Cards behind narrow slightly so the stack reads as depth. Horizontal
    // only: a uniform scale would shrink them vertically too and swallow the
    // sliver that is supposed to peek out below the card in front.
    property real stackScale: isActivated ? 1 : Math.max(0.86, 1 - (notifIndex * 0.05))
    clip: true

    Behavior on stackScale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    transform: Scale {
        origin.x: root.width / 2
        origin.y: 0
        xScale: root.stackScale
        yScale: 1
    }

    Rectangle {
        id: card
        implicitHeight: contentColumn.height
        implicitWidth: parent.width
        radius: 12

        // Collapsed, a card behind is clipped to a stackPeek strip. Shift it up
        // so the strip shows its foot - a stacked-paper edge - rather than a
        // truncated header.
        y: (root.isActivated || root.notifIndex === 0)
            ? 0
            : -Math.max(0, height - root.stackPeek)

        // Buried cards fade back so the stack reads as depth. Applied here
        // rather than on the delegate root, whose opacity the ListView add and
        // remove transitions animate - a binding there would be overwritten.
        opacity: (root.isActivated || root.notifIndex === 0)
            ? 1
            : Math.max(0.3, 0.75 - (root.notifIndex - 1) * 0.15)

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        color: root.isCritical
            ? Qt.tint(Colors.background, Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.15))
            : Colors.background
        border.color: root.isCritical ? Colors.error : Colors.border
        border.width: root.isCritical ? 2 : 1

        // Behind the content so the close and action buttons still win
        MouseArea {
            id: cardArea
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate()
        }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 0

            // Header row with app name and close button
            RowLayout {
                Layout.preferredHeight: 36
                Layout.margins: 12
                Layout.fillWidth: true

                // App icon
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: root.isCritical ? Colors.error : Colors.primary

                    Text {
                        anchors.centerIn: parent
                        text: IconService.getIcon(root.notif?.appName ?? "")
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconSmall
                        color: Colors.background
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8

                    text: root.notif?.appName ?? "Notification"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    font.bold: true
                    color: Colors.foreground
                    elide: Text.ElideRight
                }

                // Close button
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: closeArea.containsMouse ? Colors.error : Colors.surface

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconSmall
                        color: closeArea.containsMouse ? Colors.background : Colors.foreground
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.notif) {
                                root.notif.remove()
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                color: root.isCritical ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.3) : Colors.border
            }

            // Content row: square images sit to the left of the text
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                Layout.bottomMargin: notifImage.visible ? 8 : 12
                spacing: 10

                // Square sources render small, beside the text. Fixed size, so
                // its load can never move the layout.
                Image {
                    id: thumbImage
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignTop
                    visible: root.imageIsThumbnail

                    source: root.imageIsThumbnail ? root.imageSource : ""
                    sourceSize.width: 128
                    sourceSize.height: 128
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    clip: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Summary (title)
                    Text {
                        Layout.fillWidth: true

                        text: root.notif?.summary ?? ""
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.body
                        font.bold: true
                        color: Colors.foreground
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        visible: text.length > 0
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        visible: root.notif?.body?.length > 0

                        text: root.notif?.body ?? ""
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        color: Colors.foregroundAlt
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                    }
                }
            }

            // Wide/tall images (screenshots) keep the full-width preview.
            // Only loaded once the shape is known, so avatars never decode large.
            Image {
                id: notifImage
                Layout.fillWidth: true
                Layout.preferredHeight: root.previewHeight
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: root.previewHeight > 0 ? 12 : 0

                source: (root.imageProbed && !root.imageIsThumbnail) ? root.imageSource : ""
                // Both dimensions must be set: notif.image is an image:// provider
                // URL, and a half-specified sourceSize makes it return a
                // degenerate 2x1 pixmap instead of scaling.
                sourceSize.width: 400
                sourceSize.height: 400
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: root.buttonActions.length > 0 ? 12 : 0
                Layout.topMargin: 0
                Layout.preferredHeight: root.buttonActions.length > 0 ? 32 : 0
                spacing: 8
                visible: root.buttonActions.length > 0

                Repeater {
                    model: root.buttonActions

                    Rectangle {
                        id: actionBtn
                        required property var modelData

                        Layout.preferredHeight: 28
                        Layout.preferredWidth: actionText.width + 16
                        radius: 6
                        color: actionArea.containsMouse ? Colors.primary : Colors.surface

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: actionBtn.modelData?.text ?? ""
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: actionArea.containsMouse ? Colors.background : Colors.foreground
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (actionBtn.modelData) {
                                    actionBtn.modelData.invoke()
                                    // Focus the app window after invoking the action
                                    NotificationState.focusAppWindow(root.notif?.appName ?? "")
                                }
                            }
                        }
                    }
                }
            }

            // Progress bar for auto-dismiss
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                Layout.bottomMargin: 2
                radius: 2
                color: Colors.overlay
                // Hidden on buried cards: it is that card's own dismiss timer,
                // and in a 10px strip it swamps the card edge with a bright bar
                visible: (root.isActivated || root.notifIndex === 0)
                         && (root.notif?.timer?.running ?? false)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * progress
                    radius: 2
                    color: Colors.primary
                    opacity: 0.6

                    property real progress: 1.0

                    NumberAnimation on progress {
                        from: 1.0
                        to: 0.0
                        duration: root.notif?.timer?.interval ?? 5000
                        running: root.notif?.timer?.running ?? false
                    }
                }
            }
        }
    }

}
