# faiyt-qs

A feature-rich QuickShell desktop shell for Hyprland, featuring a top bar and dual sidebars with the Rosé Pine color theme.

## Features

### Top Bar
- **Clock** - Time display with click to open calendar
- **Workspaces** - Hyprland workspace indicators with click navigation
- **Window Title** - Active window name display
- **System Resources** - CPU, RAM, and temperature monitors
- **Battery** - Battery level with charging indicator
- **Music** - MPRIS media player controls (play/pause, track info)
- **System Tray** - Application tray icons with tooltips and menus
- **Network** - Connection status indicator
- **Weather** - Current weather display
- **Utilities** - Quick action buttons
- **Bar Corners** - Rounded corner decorations

### Right Sidebar
Slide-out panel with multiple tabs:

- **Notifications** - Notification center with dismiss, expand, and clear all
- **Audio Control** - Volume mixer using Pipewire
  - Output device volume and mute
  - Input (microphone) volume and mute
  - Per-application volume control
- **Bluetooth** - Device management
  - Power toggle
  - Paired device list
  - Connect/disconnect devices
  - Scan for new devices
- **WiFi** - Network management
  - Power toggle
  - Available networks list
  - Connect with password dialog
  - Signal strength indicators
- **Calendar** - Month view calendar
  - Navigate months
  - Today highlighting
  - Live clock display

**Header Section:**
- User avatar and username
- Hostname and system uptime
- Settings and power buttons

**Quick Toggles:**
- WiFi on/off
- Bluetooth on/off
- Idle inhibitor (caffeine mode)

### Left Sidebar
Developer tools panel with search and category filtering:

**Categories:** All, Dev, System, Network, Monitor

**Available Tools:**
- Git Status - Check repository status
- Docker Status - View running containers
- Port Scanner - Check common dev ports (3000, 5000, 8080, etc.)
- Clear Cache - Clear system caches
- System Info - CPU, memory, disk, uptime
- Process Monitor - Top CPU/memory processes
- DNS Flush - Flush DNS cache
- Node Version - Check Node.js, npm, Bun versions
- Disk Usage - Check disk space
- Network Info - View network interfaces

### Notification Popups
Toast notifications that appear when notifications arrive:
- Stack from top-right corner (up to 5)
- Auto-dismiss after 5 seconds with progress indicator
- Pause timer on hover
- App-specific icons
- Click to dismiss

## Requirements

- [QuickShell](https://quickshell.outfoxxed.me/)
- Hyprland (or other Wayland compositor)
- [Symbols Nerd Font](https://www.nerdfonts.com/) for icons
- Pipewire (for audio controls)
- NetworkManager (for WiFi controls)
- BlueZ (for Bluetooth controls)

## Installation

```bash
git clone https://github.com/yourusername/faiyt-qs.git
cd faiyt-qs
```

## Running

```bash
quickshell -p shell.qml
```

Or from anywhere:
```bash
quickshell -p /path/to/faiyt-qs/shell.qml
```

## Project Structure

```
faiyt-qs/
├── shell.qml                    # Main entry point
├── theme/
│   ├── Colors.qml               # Rosé Pine color definitions
│   └── qmldir
├── components/
│   ├── bar/
│   │   ├── Bar.qml              # Top bar panel
│   │   ├── BarGroup.qml         # Widget grouping
│   │   ├── corners/
│   │   │   ├── BarCornerLeft.qml
│   │   │   └── BarCornerRight.qml
│   │   └── modules/
│   │       ├── Clock.qml
│   │       ├── Workspaces.qml
│   │       ├── WindowTitle.qml
│   │       ├── SystemResources.qml
│   │       ├── Battery.qml
│   │       ├── Music.qml
│   │       ├── SystemTray.qml
│   │       ├── Network.qml
│   │       ├── Weather.qml
│   │       └── Utilities.qml
│   ├── sidebar/
│   │   ├── SidebarState.qml     # Shared sidebar state
│   │   ├── SidebarOverlay.qml   # Click-away overlay
│   │   ├── SidebarLeft.qml      # Left sidebar panel
│   │   ├── SidebarRight.qml     # Right sidebar panel
│   │   └── modules/
│   │       ├── Header.qml
│   │       ├── QuickToggles.qml
│   │       ├── TabBar.qml
│   │       ├── Notifications.qml
│   │       ├── AudioControl.qml
│   │       ├── BluetoothPanel.qml
│   │       ├── WiFiPanel.qml
│   │       ├── Calendar.qml
│   │       ├── Tools.qml
│   │       └── ToolItem.qml
│   └── notifications/
│       ├── NotificationServer.qml  # Singleton notification daemon
│       └── NotificationPopups.qml  # Popup windows
└── README.md
```

## Configuration

### Sidebar Keybindings (Hyprland)

Add to your `hyprland.conf`:

```conf
# Toggle right sidebar
bind = SUPER, N, exec, quickshell -c 'SidebarState.rightOpen = !SidebarState.rightOpen'

# Toggle left sidebar
bind = SUPER, T, exec, quickshell -c 'SidebarState.leftOpen = !SidebarState.leftOpen'
```

Or use the bar's utility buttons to toggle sidebars.

## Theme (Rosé Pine)

| Color          | Hex       | Usage                |
|----------------|-----------|----------------------|
| background     | #191724   | Main background      |
| surface        | #1f1d2e   | Elevated surfaces    |
| overlay        | #26233a   | Borders, overlays    |
| foreground     | #e0def4   | Primary text         |
| foregroundAlt  | #908caa   | Secondary text       |
| foregroundMuted| #6e6a86   | Muted text           |
| primary        | #c4a7e7   | Primary accent (iris)|
| error          | #eb6f92   | Error states (love)  |
| warning        | #f6c177   | Warning (gold)       |
| success        | #9ccfd8   | Success (foam)       |
| info           | #31748f   | Info (pine)          |

## Shell Commands Used

The shell uses various system commands for functionality:

- `nmcli` - WiFi management
- `bluetoothctl` - Bluetooth management
- `wpctl` / Pipewire - Audio control
- `systemctl` - Power management, idle inhibit
- `hyprctl` - Workspace management
- Standard Unix utilities (`uptime`, `whoami`, `hostname`, etc.)

## Credits

- [QuickShell](https://quickshell.outfoxxed.me/) - The shell framework
- [Rosé Pine](https://rosepinetheme.com/) - Color theme
- [Nerd Fonts](https://www.nerdfonts.com/) - Icon font

## License

MIT
