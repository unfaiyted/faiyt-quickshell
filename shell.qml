//@ pragma UseQApplication
import QtQuick
import Quickshell
import "components/bar"
import "components/bar/corners"
import "components/sidebar"
import "components/notifications"
import "components/wallpaper"
import "components/launcher"

ShellRoot {
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
