import QtQuick
import Quickshell
import "../../../theme"
import ".."
import "../../wallpaper"

BarGroup {
    id: utilities

    implicitWidth: utilRow.width + 16
    implicitHeight: 24

    Row {
        id: utilRow
        anchors.centerIn: parent
        spacing: 8

        // Screenshot button - use hyprctl dispatch exec for proper Wayland access
        UtilityButton {
            property string scriptPath: Quickshell.env("HOME") + "/codebase/faiyt-qs/scripts/screen-capture.sh"
            icon: "󰄀"
            tooltip: "Screenshot"
            command: ["hyprctl", "dispatch", "exec", scriptPath + " screenshot selection"]
        }

        // Recording button
        RecordingButton {}

        // Color picker button - use hyprctl dispatch exec for proper Wayland access
        UtilityButton {
            icon: "󰴱"
            tooltip: "Color Picker"
            command: ["hyprctl", "dispatch", "exec", "hyprpicker -a"]
        }

        // Wallpaper button
        UtilityButton {
            icon: "󰸉"
            tooltip: "Wallpapers"
            onActivate: function() { WallpaperState.toggle() }
        }
    }
}
