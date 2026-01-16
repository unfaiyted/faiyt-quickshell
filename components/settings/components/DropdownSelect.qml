import QtQuick
import "../../../theme"
import "../../common"

Item {
    id: dropdown

    property var model: []
    property int currentIndex: 0
    property var currentValue: model.length > 0 ? model[currentIndex].value : null
    property string currentLabel: model.length > 0 ? model[currentIndex].label : ""
    property bool popupOpen: false
    property bool enableSearch: false  // Optional search feature
    property string previewText: "Aa Bb Cc"  // For font previews
    property string hintScope: "settings"
    signal selected(int index, var value)

    // Find any DropdownOverlay in parent hierarchy
    property var dropdownOverlay: findDropdownOverlay()

    function findDropdownOverlay() {
        let p = dropdown.parent
        while (p) {
            // Check for dropdownOverlayRef property (panels that have a DropdownOverlay)
            if (p.dropdownOverlayRef) {
                return p.dropdownOverlayRef
            }
            // Check for ThemePanel which has dropdown functions
            if (p.openDropdown && p.closeDropdown && p.selectDropdownItem) {
                return {
                    isThemePanel: true,
                    panel: p
                }
            }
            p = p.parent
        }
        return null
    }

    width: 150
    height: 32

    // Listen for selection from overlay
    Connections {
        target: dropdown.dropdownOverlay && !dropdown.dropdownOverlay.isThemePanel ? dropdown.dropdownOverlay : null
        enabled: dropdown.dropdownOverlay !== null && (dropdown.dropdownOverlay.isThemePanel !== true)
        function onItemSelected(index, value) {
            if (dropdown.dropdownOverlay.activeSource === dropdown) {
                dropdown.currentIndex = index
                dropdown.selected(index, value)
            }
        }
    }

    // Listen for ThemePanel dropdown selection
    Connections {
        target: dropdown.dropdownOverlay && dropdown.dropdownOverlay.isThemePanel ? dropdown.dropdownOverlay.panel : null
        enabled: dropdown.dropdownOverlay !== null && (dropdown.dropdownOverlay.isThemePanel === true)
        function onDropdownSelected(index, value) {
            if (dropdown.dropdownOverlay.panel.activeDropdownSource === dropdown) {
                dropdown.currentIndex = index
                dropdown.selected(index, value)
            }
        }
    }

    Rectangle {
        id: button
        anchors.fill: parent
        radius: 8
        color: buttonArea.containsMouse || dropdown.popupOpen
            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
        border.width: 1
        border.color: dropdown.popupOpen
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
            : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8

            Text {
                width: parent.width - arrow.width - 8
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: dropdown.currentLabel
                font.family: Fonts.ui
                font.pixelSize: Fonts.body
                color: Colors.foreground
                elide: Text.ElideRight
            }

            Text {
                id: arrow
                width: 16
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: dropdown.popupOpen ? "󰅃" : "󰅀"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconSmall
                color: Colors.foregroundAlt
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dropdown.toggleDropdown()
        }

        HintTarget {
            targetElement: button
            scope: dropdown.hintScope
            action: () => dropdown.toggleDropdown()
        }
    }

    function toggleDropdown() {
        if (dropdown.dropdownOverlay) {
            if (dropdown.popupOpen) {
                if (dropdown.dropdownOverlay.isThemePanel) {
                    dropdown.dropdownOverlay.panel.closeDropdown()
                } else {
                    dropdown.dropdownOverlay.close()
                }
            } else {
                if (dropdown.dropdownOverlay.isThemePanel) {
                    dropdown.dropdownOverlay.panel.openDropdown(dropdown, dropdown.model, dropdown.currentIndex, dropdown.previewText, dropdown.enableSearch)
                } else {
                    dropdown.dropdownOverlay.open(dropdown, dropdown.model, dropdown.currentIndex, dropdown.enableSearch, dropdown.previewText)
                }
            }
        }
    }

    onVisibleChanged: {
        if (!visible && dropdownOverlay) {
            if (dropdownOverlay.isThemePanel) {
                dropdownOverlay.panel.closeDropdown()
            } else {
                dropdownOverlay.close()
            }
        }
    }

    function close() {
        if (dropdownOverlay) {
            if (dropdownOverlay.isThemePanel) {
                dropdownOverlay.panel.closeDropdown()
            } else {
                dropdownOverlay.close()
            }
        }
    }
}
