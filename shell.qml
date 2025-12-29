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

ShellRoot {
    id: root

    // Create required directories on startup
    Component.onCompleted: {
        initDirs.running = true
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
    WallpaperWindow {}
    LauncherWindow {}
}
