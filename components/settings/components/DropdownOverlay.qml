import QtQuick
import "../../../theme"

Item {
    id: dropdownOverlay

    // State properties
    property var activeSource: null
    property var model: []
    property int currentIndex: 0
    property int highlightIndex: 0
    property string searchText: ""
    property string previewText: "Aa Bb Cc"
    property bool showSearch: false
    property bool isVisible: false

    // Filtered model
    property var filteredModel: filterModel()

    signal itemSelected(int index, var value)

    function filterModel() {
        if (!model || model.length === 0) return []
        if (!searchText || searchText.trim() === "") {
            return showSearch ? model.slice(0, 25) : model
        }
        let search = searchText.toLowerCase().trim()
        let filtered = model.filter(item =>
            item.label.toLowerCase().includes(search)
        )
        return filtered.slice(0, 25)
    }

    onSearchTextChanged: {
        filteredModel = filterModel()
        highlightIndex = 0
    }

    onModelChanged: {
        filteredModel = filterModel()
    }

    function open(sourceItem, dropdownModel, selectedIndex, enableSearch, preview) {
        if (activeSource && activeSource !== sourceItem) {
            activeSource.popupOpen = false
        }
        activeSource = sourceItem
        model = dropdownModel
        currentIndex = selectedIndex
        highlightIndex = selectedIndex  // Start at current selection
        showSearch = enableSearch || false
        previewText = preview || "Aa Bb Cc"
        searchText = ""
        isVisible = true
        if (sourceItem) sourceItem.popupOpen = true
    }

    function close() {
        if (activeSource) activeSource.popupOpen = false
        activeSource = null
        model = []
        searchText = ""
        isVisible = false
    }

    function selectItem(index, value) {
        currentIndex = index
        itemSelected(index, value)
        close()
    }

    function keyNav(key) {
        let count = filteredModel.length
        if (count === 0) return

        if (key === Qt.Key_Down) {
            highlightIndex = (highlightIndex + 1) % count
            ensureVisible()
        } else if (key === Qt.Key_Up) {
            highlightIndex = (highlightIndex - 1 + count) % count
            ensureVisible()
        } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            if (highlightIndex >= 0 && highlightIndex < count) {
                let item = filteredModel[highlightIndex]
                selectItem(highlightIndex, item.value)
            }
        } else if (key === Qt.Key_Escape) {
            close()
        }
    }

    function ensureVisible() {
        let itemHeight = showSearch ? 40 : 32
        let targetY = highlightIndex * (itemHeight + 2)
        if (targetY < listFlickable.contentY) {
            listFlickable.contentY = targetY
        } else if (targetY + itemHeight > listFlickable.contentY + listFlickable.height) {
            listFlickable.contentY = targetY + itemHeight - listFlickable.height
        }
    }

    anchors.fill: parent

    // Backdrop to close on click outside
    MouseArea {
        anchors.fill: parent
        visible: dropdownOverlay.isVisible
        z: 200
        onClicked: dropdownOverlay.close()
    }

    // Dropdown popup
    Rectangle {
        id: popup
        visible: dropdownOverlay.isVisible
        z: 201
        width: dropdownOverlay.showSearch ? 280 : 180
        height: {
            let searchHeight = dropdownOverlay.showSearch ? 52 : 0
            let listHeight = Math.min(listColumn.height, dropdownOverlay.showSearch ? 250 : 200)
            return searchHeight + listHeight + 16
        }
        radius: 8
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)

        // Position below source
        x: {
            if (!dropdownOverlay.activeSource) return 100
            let mapped = dropdownOverlay.mapFromItem(dropdownOverlay.activeSource, 0, 0)
            return Math.max(20, Math.min(dropdownOverlay.width - width - 20, mapped.x))
        }
        y: {
            if (!dropdownOverlay.activeSource) return 100
            let mapped = dropdownOverlay.mapFromItem(dropdownOverlay.activeSource, 0, dropdownOverlay.activeSource.height)
            if (mapped.y + height > dropdownOverlay.height - 20) {
                return Math.max(20, mapped.y - dropdownOverlay.activeSource.height - height - 8)
            }
            return Math.min(dropdownOverlay.height - height - 20, mapped.y + 4)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: (event) => event.accepted = true
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            spacing: 4

            // Hidden focus item for keyboard nav when no search field
            Item {
                id: keyboardFocus
                visible: !dropdownOverlay.showSearch
                width: 0
                height: 0
                focus: !dropdownOverlay.showSearch && dropdownOverlay.isVisible

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                        event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
                        event.key === Qt.Key_Escape) {
                        dropdownOverlay.keyNav(event.key)
                        event.accepted = true
                    }
                }
            }

            // Search field
            Rectangle {
                visible: dropdownOverlay.showSearch
                width: parent.width
                height: 32
                radius: 6
                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.5)
                border.width: 1
                border.color: searchInput.activeFocus
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                    : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: "󰍉"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconSmall
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 24
                        height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        color: Colors.foreground
                        clip: true
                        text: dropdownOverlay.searchText
                        onTextChanged: dropdownOverlay.searchText = text

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                                event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
                                event.key === Qt.Key_Escape) {
                                dropdownOverlay.keyNav(event.key)
                                event.accepted = true
                            }
                        }

                        Text {
                            visible: !searchInput.text && !searchInput.activeFocus
                            text: "Search..."
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Results count (for search mode)
            Text {
                visible: dropdownOverlay.showSearch
                width: parent.width
                text: {
                    let total = dropdownOverlay.model.length
                    let shown = dropdownOverlay.filteredModel.length
                    if (dropdownOverlay.searchText) {
                        return shown + " matches" + (shown >= 25 ? " (first 25)" : "")
                    }
                    return "Showing 25 of " + total
                }
                font.family: Fonts.ui
                font.pixelSize: Fonts.tiny
                color: Colors.foregroundMuted
                horizontalAlignment: Text.AlignRight
                rightPadding: 4
            }

            Flickable {
                id: listFlickable
                width: parent.width
                height: Math.min(listColumn.height, dropdownOverlay.showSearch ? 250 : 200)
                contentHeight: listColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: listColumn
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: dropdownOverlay.filteredModel

                        Rectangle {
                            id: listItem
                            width: listColumn.width
                            height: dropdownOverlay.showSearch ? 40 : 32
                            radius: 6

                            property bool isHovered: itemMouse.containsMouse
                            property bool isKeyHighlighted: index === dropdownOverlay.highlightIndex
                            property bool isSelected: index === dropdownOverlay.currentIndex
                            property bool isHighlighted: isHovered || isKeyHighlighted

                            color: isHighlighted
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
                                : (isSelected
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                    : "transparent")

                            Behavior on color { ColorAnimation { duration: 100 } }

                            // Font picker style (with preview)
                            Column {
                                visible: dropdownOverlay.showSearch
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.topMargin: 6
                                anchors.bottomMargin: 6
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData.label
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    color: listItem.isHighlighted || listItem.isSelected ? Colors.foreground : Colors.foregroundAlt
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: modelData.value !== "" && (listItem.isHighlighted || listItem.isSelected)
                                    width: parent.width
                                    text: dropdownOverlay.previewText
                                    font.pixelSize: Fonts.small
                                    font.family: modelData.value
                                    color: Colors.foreground
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: modelData.value !== "" && !listItem.isHighlighted && !listItem.isSelected
                                    width: parent.width
                                    text: dropdownOverlay.previewText
                                    font.pixelSize: Fonts.small
                                    font.italic: true
                                    color: Colors.foregroundMuted
                                    elide: Text.ElideRight
                                }
                            }

                            // Simple style (no search)
                            Text {
                                visible: !dropdownOverlay.showSearch
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.label
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.body
                                color: listItem.isHighlighted || listItem.isSelected ? Colors.foreground : Colors.foregroundAlt
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dropdownOverlay.selectItem(index, modelData.value)
                            }
                        }
                    }
                }
            }
        }

        // Focus appropriate element on open
        Connections {
            target: dropdownOverlay
            function onIsVisibleChanged() {
                if (dropdownOverlay.isVisible) {
                    if (dropdownOverlay.showSearch) {
                        searchInput.forceActiveFocus()
                    } else {
                        keyboardFocus.forceActiveFocus()
                    }
                }
            }
        }
    }
}
