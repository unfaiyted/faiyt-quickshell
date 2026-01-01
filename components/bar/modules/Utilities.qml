import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"
import ".."
import "../../wallpaper"

BarGroup {
    id: utilities

    implicitWidth: utilRow.width + 16
    implicitHeight: 30

    // Hide entire group if all buttons are hidden
    visible: ConfigService.barUtilityScreenshot || ConfigService.barUtilityRecording ||
             ConfigService.barUtilityColorPicker || ConfigService.barUtilityWallpaper

    Row {
        id: utilRow
        anchors.centerIn: parent
        spacing: 8

        // Screenshot button with right-click context menu for annotation
        ScreenshotButton {
            visible: ConfigService.barUtilityScreenshot
        }

        // Recording button
        RecordingButton {
            visible: ConfigService.barUtilityRecording
        }

        // Color picker button - use hyprctl dispatch exec for proper Wayland access
        UtilityButton {
            icon: "󰴱"
            tooltip: "Color Picker"
            command: ["hyprctl", "dispatch", "exec", "hyprpicker -a"]
            visible: ConfigService.barUtilityColorPicker
        }

        // Wallpaper button
        UtilityButton {
            icon: "󰸉"
            tooltip: "Wallpapers"
            onActivate: function() { WallpaperState.toggle() }
            visible: ConfigService.barUtilityWallpaper
        }
    }
}
