import QtQuick
import "../theme"

BarGroup {
    id: utilities

    implicitWidth: utilRow.width + 16
    implicitHeight: 24

    Row {
        id: utilRow
        anchors.centerIn: parent
        spacing: 8

        // Screenshot button
        UtilityButton {
            icon: "󰄀"
            tooltip: "Screenshot"
            command: ["grimblast", "copy", "area"]
        }

        // Color picker button
        UtilityButton {
            icon: "󰴱"
            tooltip: "Color Picker"
            command: ["hyprpicker", "-a"]
        }
    }
}
