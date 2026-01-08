import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../services"
import "../common"
import "../settings/components"

Rectangle {
    id: requirementsPanel

    width: 500
    height: Math.min(parent ? parent.height * 0.8 : 600, 700)
    radius: 20
    color: Colors.background
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

    // Scroll functions for keyboard navigation
    function scrollUp() {
        scrollAnim.to = Math.max(0, contentFlickable.contentY - 60)
        scrollAnim.restart()
    }

    function scrollDown() {
        scrollAnim.to = Math.min(contentFlickable.contentHeight - contentFlickable.height, contentFlickable.contentY + 60)
        scrollAnim.restart()
    }

    function scrollPageUp() {
        scrollAnim.to = Math.max(0, contentFlickable.contentY - contentFlickable.height * 0.8)
        scrollAnim.restart()
    }

    function scrollPageDown() {
        scrollAnim.to = Math.min(contentFlickable.contentHeight - contentFlickable.height, contentFlickable.contentY + contentFlickable.height * 0.8)
        scrollAnim.restart()
    }

    function scrollToTop() {
        scrollAnim.to = 0
        scrollAnim.restart()
    }

    function scrollToBottom() {
        scrollAnim.to = contentFlickable.contentHeight - contentFlickable.height
        scrollAnim.restart()
    }

    NumberAnimation {
        id: scrollAnim
        target: contentFlickable
        property: "contentY"
        duration: 150
        easing.type: Easing.OutCubic
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            width: parent.width
            height: 40

            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "System Requirements"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.xlarge
                    font.weight: Font.Bold
                    color: Colors.foreground
                }

                Text {
                    text: RequirementsService.checkComplete
                        ? (RequirementsService.installedCount + "/" + RequirementsService.totalCount + " dependencies available")
                        : "Checking dependencies..."
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foregroundMuted
                }
            }

            // Close button
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: closeArea.containsMouse
                    ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)
                    : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconMedium
                    color: Colors.foregroundAlt
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: RequirementsState.close()
                }

                HintTarget {
                    targetElement: parent
                    scope: "requirements"
                    action: function() { RequirementsState.close() }
                }
            }
        }

        // Progress bar
        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)

            Rectangle {
                width: RequirementsService.checkComplete
                    ? parent.width * (RequirementsService.installedCount / RequirementsService.totalCount)
                    : 0
                height: parent.height
                radius: 3
                color: RequirementsService.hasMissingRequired
                    ? Colors.error
                    : (RequirementsService.hasMissingOptional ? Colors.warning : Colors.foam)

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        // Status message
        Rectangle {
            visible: RequirementsService.checkComplete && RequirementsService.hasMissingRequired
            width: parent.width
            height: visible ? 36 : 0
            radius: 8
            color: Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.3)

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: ""
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconMedium
                    color: Colors.error
                }

                Text {
                    text: "Some required dependencies are missing"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.error
                }
            }
        }

        // Content area
        Flickable {
            id: contentFlickable
            width: parent.width
            height: parent.height - 40 - 6 - 60 - 16 * 3 - (RequirementsService.hasMissingRequired ? 36 + 16 : 0)
            contentHeight: categoriesColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 6
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.2)
                }
            }

            Column {
                id: categoriesColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: RequirementsService.categories

                    delegate: CategorySection {
                        width: categoriesColumn.width
                        categoryName: modelData
                    }
                }
            }
        }

        // Footer
        RowLayout {
            width: parent.width
            height: 40

            // Don't show on startup checkbox
            Row {
                spacing: 8

                Rectangle {
                    id: checkbox
                    width: 20
                    height: 20
                    radius: 4
                    color: dontShowChecked
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.8)
                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)
                    border.width: 1
                    border.color: dontShowChecked
                        ? Colors.primary
                        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)

                    property bool dontShowChecked: ConfigService.getValue("requirements.dontShowOnStartup", false)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconSmall
                        color: Colors.foreground
                        visible: checkbox.dontShowChecked
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let newValue = !checkbox.dontShowChecked
                            ConfigService.setValue("requirements.dontShowOnStartup", newValue)
                            checkbox.dontShowChecked = newValue
                        }
                    }

                    HintTarget {
                        targetElement: checkbox
                        scope: "requirements"
                        action: function() {
                            let newValue = !checkbox.dontShowChecked
                            ConfigService.setValue("requirements.dontShowOnStartup", newValue)
                            checkbox.dontShowChecked = newValue
                        }
                    }
                }

                Text {
                    text: "Don't show on startup"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foregroundAlt
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Refresh button
            Rectangle {
                width: 80
                height: 32
                radius: 8
                color: refreshArea.containsMouse
                    ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)
                    : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foreground
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: RequirementsService.refresh()
                }

                HintTarget {
                    targetElement: parent
                    scope: "requirements"
                    action: function() { RequirementsService.refresh() }
                }
            }

            // Close button
            Rectangle {
                width: 80
                height: 32
                radius: 8
                color: closeButtonArea.containsMouse
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.primary
                }

                MouseArea {
                    id: closeButtonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: RequirementsState.close()
                }

                HintTarget {
                    targetElement: parent
                    scope: "requirements"
                    action: function() { RequirementsState.close() }
                }
            }
        }
    }

    // Category section component
    component CategorySection: Item {
        id: categorySection

        property string categoryName: ""
        property var stats: RequirementsService.getCategoryStats(categoryName)
        property var items: RequirementsService.getByCategory(categoryName)
        property bool expanded: stats.missingRequired || (categoryName === "Environment")

        width: parent.width
        implicitHeight: headerRect.height + (expanded ? contentContainer.height + 8 : 0)
        clip: true

        Behavior on implicitHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: headerRect
            width: parent.width
            height: 36
            radius: 8
            color: headerArea.containsMouse
                ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
            border.width: 1
            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.08)

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                // Chevron
                Text {
                    text: ""
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconSmall
                    color: Colors.foregroundAlt
                    rotation: categorySection.expanded ? 90 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                // Category name
                Text {
                    text: categorySection.categoryName
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.body
                    font.weight: Font.Medium
                    color: Colors.foreground
                }

                Item { Layout.fillWidth: true }

                // Status badge
                Rectangle {
                    width: statusText.width + 12
                    height: 20
                    radius: 10
                    color: categorySection.stats.missingRequired
                        ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.2)
                        : (categorySection.stats.installed === categorySection.stats.total
                            ? Qt.rgba(Colors.foam.r, Colors.foam.g, Colors.foam.b, 0.2)
                            : Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.2))

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: categorySection.stats.installed + "/" + categorySection.stats.total
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        color: categorySection.stats.missingRequired
                            ? Colors.error
                            : (categorySection.stats.installed === categorySection.stats.total
                                ? Colors.foam
                                : Colors.warning)
                    }
                }
            }

            MouseArea {
                id: headerArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: categorySection.expanded = !categorySection.expanded
            }

            HintTarget {
                targetElement: headerRect
                scope: "requirements"
                action: function() { categorySection.expanded = !categorySection.expanded }
            }
        }

        Item {
            id: contentContainer
            anchors.top: headerRect.bottom
            anchors.topMargin: 8
            width: parent.width
            height: contentColumn.height
            visible: categorySection.expanded || opacityAnim.running
            opacity: categorySection.expanded ? 1 : 0

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

                Repeater {
                    model: categorySection.items

                    delegate: Rectangle {
                        width: contentColumn.width
                        height: 32
                        radius: 6
                        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            // Status icon
                            Text {
                                text: modelData.installed ? "" : ""
                                font.family: Fonts.icon
                                font.pixelSize: Fonts.iconSmall
                                color: modelData.installed
                                    ? Colors.foam
                                    : (modelData.required ? Colors.error : Colors.warning)
                            }

                            // Tool name
                            Text {
                                text: modelData.name
                                font.pixelSize: Fonts.small
                                font.family: Fonts.mono
                                color: Colors.foreground
                            }

                            // Required badge
                            Rectangle {
                                visible: modelData.required
                                width: reqText.width + 8
                                height: 16
                                radius: 4
                                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)

                                Text {
                                    id: reqText
                                    anchors.centerIn: parent
                                    text: "required"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.tiny
                                    color: Colors.primary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Description
                            Text {
                                text: modelData.description
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.small
                                color: Colors.foregroundMuted
                            }
                        }
                    }
                }
            }
        }
    }
}
