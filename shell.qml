//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "components/bar"
import "components/bar/corners"
import "components/sidebar"
import "components/notifications"
import "components/wallpaper"
import "components/launcher"
import "components/overview"
import "components/settings"
import "components/monitors"
import "components/requirements"
import "components/indicators"
import "services"

ShellRoot {
    id: root

    // Create required directories on startup
    Component.onCompleted: {
        initDirs.running = true
        // Initialize battery monitoring service
        if (BatteryService.hasBattery) {
            console.log("Battery monitoring active")
        }
    }

    // Show requirements panel on startup if there are missing required dependencies
    Connections {
        target: RequirementsService
        function onCheckCompleteChanged() {
            if (RequirementsService.checkComplete &&
                RequirementsService.hasMissingRequired &&
                !ConfigService.getValue("requirements.dontShowOnStartup", false)) {
                RequirementsState.open()
            }
        }
    }

    Process {
        id: initDirs
        command: ["bash", "-c", "mkdir -p ~/Pictures/Screenshots ~/Videos/Recordings"]
    }

    Bar {}
    BarCornerLeft {}
    BarCornerRight {}
    SidebarOverlay {}  // Must be before sidebars for stacking order
    SidebarLeft {}
    SidebarRight {}
    NotificationPopups {}
    IndicatorWindow {}
    WallpaperWindow {}
    LauncherWindow {}
    Overview {}
    SettingsWindow {}
    ThemePanelWindow {}
    MonitorsWindow {}
    RequirementsWindow {}
}
