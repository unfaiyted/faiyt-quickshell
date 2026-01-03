import QtQuick
import "../../../theme"
import "../../../services"

Item {
    id: fontPicker

    property var model: []
    property int currentIndex: 0
    property var currentValue: model.length > 0 ? model[currentIndex].value : ""
    property string currentLabel: model.length > 0 ? model[currentIndex].label : ""
    property string previewText: "Aa Bb Cc"
    property bool showPreview: true
    property bool popupOpen: false
    signal selected(int index, var value)

    // Find any DropdownOverlay or ThemePanel in parent hierarchy
    property var dropdownOverlay: findDropdownOverlay()

    function findDropdownOverlay() {
        let p = fontPicker.parent
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

    width: 200
    height: 36

    // Listen for selection from DropdownOverlay
    Connections {
        target: fontPicker.dropdownOverlay && !fontPicker.dropdownOverlay.isThemePanel ? fontPicker.dropdownOverlay : null
        enabled: fontPicker.dropdownOverlay !== null && !fontPicker.dropdownOverlay.isThemePanel
        function onItemSelected(index, value) {
            if (fontPicker.dropdownOverlay.activeSource === fontPicker) {
                fontPicker.currentIndex = index
                fontPicker.selected(index, value)
            }
        }
    }

    // Listen for ThemePanel dropdown selection
    Connections {
        target: fontPicker.dropdownOverlay && fontPicker.dropdownOverlay.isThemePanel ? fontPicker.dropdownOverlay.panel : null
        enabled: fontPicker.dropdownOverlay !== null && fontPicker.dropdownOverlay.isThemePanel
        function onDropdownSelected(index, value) {
            if (fontPicker.dropdownOverlay.panel.activeDropdownSource === fontPicker) {
                fontPicker.currentIndex = index
                fontPicker.selected(index, value)
            }
        }
    }

    Rectangle {
        id: button
        anchors.fill: parent
        radius: 8
        color: buttonArea.containsMouse || fontPicker.popupOpen
            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
        border.width: 1
        border.color: fontPicker.popupOpen
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
            : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 8

            Column {
                width: parent.width - arrow.width - 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: fontPicker.currentLabel
                    font.pixelSize: 12
                    font.family: fontPicker.currentValue !== "" ? fontPicker.currentValue : Qt.application.font.family
                    color: Colors.foreground
                    elide: Text.ElideRight
                }

                Text {
                    visible: fontPicker.showPreview && fontPicker.currentValue !== ""
                    width: parent.width
                    text: fontPicker.previewText
                    font.pixelSize: 10
                    font.family: fontPicker.currentValue !== "" ? fontPicker.currentValue : Qt.application.font.family
                    color: Colors.foregroundAlt
                    elide: Text.ElideRight
                }
            }

            Text {
                id: arrow
                width: 16
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: fontPicker.popupOpen ? "󰅃" : "󰅀"
                font.family: Fonts.icon
                font.pixelSize: 12
                color: Colors.foregroundAlt
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (fontPicker.dropdownOverlay) {
                    if (fontPicker.popupOpen) {
                        if (fontPicker.dropdownOverlay.isThemePanel) {
                            fontPicker.dropdownOverlay.panel.closeDropdown()
                        } else {
                            fontPicker.dropdownOverlay.close()
                        }
                    } else {
                        // Font pickers always enable search
                        if (fontPicker.dropdownOverlay.isThemePanel) {
                            fontPicker.dropdownOverlay.panel.openDropdown(fontPicker, fontPicker.model, fontPicker.currentIndex, fontPicker.previewText, true)
                        } else {
                            fontPicker.dropdownOverlay.open(fontPicker, fontPicker.model, fontPicker.currentIndex, true, fontPicker.previewText)
                        }
                    }
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

    function setValueByName(fontName) {
        for (let i = 0; i < model.length; i++) {
            if (model[i].value === fontName) {
                currentIndex = i
                return
            }
        }
        currentIndex = 0
    }
}
