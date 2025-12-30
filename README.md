# faiyt-qs

A feature-rich QuickShell desktop shell for Hyprland, featuring a top bar and dual sidebars with the Rosé Pine color theme.

## Features

### Top Bar
- **Clock** - Time display with click to open calendar
- **Workspaces** - Hyprland workspace indicators with:
  - Click to switch workspace
  - Hover for live window preview tooltip
  - Click windows in tooltip to focus them
  - Middle-click windows to close them
- **Window Title** - Active window name with app icon
- **System Resources** - Resource monitors with circular progress and nerd font icons:
  - RAM usage with used/total details
  - Swap usage
  - CPU usage with load average
  - Network download speed (% of max bandwidth)
  - Network upload speed (% of max bandwidth)
- **Battery** - Battery level with charging indicator
- **Music** - MPRIS media player with interactive tooltip:
  - Animated audio visualization bars (cava) when playing
  - Album art display with fallback placeholder
  - Track info (title, artist, album)
  - Seekable progress bar with time display
  - Playback controls (previous, play/pause, next)
  - Simulated animation when no local audio (e.g., Spotify Connect)
  - Click outside to dismiss
- **System Tray** - Application tray icons with tooltips and menus
- **Network** - Connection status indicator
- **Weather** - Current weather display
- **Utilities** - Quick action buttons:
  - Screenshot (area selection)
  - Screen Recording with status indicator
  - Color Picker
  - Wallpaper Picker
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
- User avatar (profile picture from AccountsService, or letter fallback)
- Username, hostname, and system uptime
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

### Launcher
Application launcher with instant evaluators and multiple search modes:

**Search Types:**
- **Apps** (`app:`, `a:`) - Search and launch desktop applications
- **Windows** (`win:`, `window:`, `w:`) - Search open windows with live previews
- **Commands** (`cmd:`, `$:`, `>:`) - Run shell commands with history
- **System** (`sys:`) - Power actions (shutdown, reboot, suspend, lock, logout)

**Instant Evaluators:**
Real-time calculations displayed on the right side of the input as you type:

| Type | Examples | Output |
|------|----------|--------|
| Math | `5 + 3`, `2^8`, `(10+5)*2` | `= 8`, `= 256`, `= 30` |
| Percentage | `20% of 150`, `15% off 80` | `= 30`, `= 68` |
| Units | `100km to miles`, `72f to c` | `= 62.14 miles`, `= 22.22°C` |
| Base | `255 to hex`, `0xFF` | `= 0xFF`, `= 255 (dec)` |
| Time | `2h 30m to minutes` | `= 150 min` |
| Color | `#eb6f92`, `red to rgb` | Shows color swatch + formats |

**Features:**
- Press Enter to copy evaluator result to clipboard
- Click on result to copy
- Color swatch preview for color conversions
- "Copied!" feedback animation

**Keyboard Navigation:**
- `↑`/`↓` or `Ctrl+K`/`Ctrl+J` - Navigate results
- `Enter` - Activate selected / Copy eval result
- `Escape` - Close launcher

### Screen Capture
Screenshot and screen recording functionality with area selection:

**Screenshots:**
- Click the screenshot button or use IPC
- Select area with slurp
- Saved to `~/Pictures/Screenshots/` with timestamp
- Copied to clipboard automatically

**Screen Recording:**
- Left-click the recording button to start (red pulsing indicator when active)
- Right-click to select recording mode before starting
- Select area with slurp
- Click again to stop recording
- Saved to `~/Videos/Recordings/` as MP4 (HEVC NVENC hardware encoding)
- File path copied to clipboard on completion
- Desktop notification on save

**Recording Modes** (right-click menu):
- **Standard** - Regular MP4 recording with hardware HEVC (supports 8K resolution)
- **High Quality** - 60fps, high quality HEVC for YouTube uploads
- **GIF** - Records at 15fps, auto-converts to optimized GIF

**Recording Targets:**
- `selection` - Record selected area (default)
- `eDP-1` - Record primary display
- `HDMI-A-1` - Record external display
- `stop` - Stop current recording

### Overview Mode
Full-screen workspace overview with live window previews:

- **2x5 Workspace Grid** - Shows all 10 workspaces at once
- **Live Window Previews** - Real-time screencopy of all windows
- **App Icons** - Centered icon overlay on each window
- **Keyboard Navigation**:
  - Arrow keys or `hjkl` - Move between workspaces
  - Number keys `1-9`, `0` - Jump to specific workspace
  - `Enter` - Activate selected workspace
  - `Escape` - Close overview
- **Mouse Actions**:
  - Click workspace - Switch to it
  - Click window - Focus and close overview
  - Middle-click window - Close window
  - Drag window - Move to different workspace
- **Click outside** to close

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
- wl-clipboard (`wl-copy`) for clipboard operations

**Screen Capture Dependencies:**
- `grim` - Screenshot utility for Wayland
- `slurp` - Area selection tool
- `wf-recorder` - Screen recording for Wayland
- `hyprpicker` - Color picker for Hyprland
- `notify-send` - Desktop notifications (libnotify)

**Music Visualization:**
- `cava` - Audio visualizer for animated bars in the music module

## Installation

```bash
git clone https://github.com/yourusername/faiyt-qs.git
cd faiyt-qs
```

The shell will automatically create the following directories on startup if they don't exist:
- `~/Pictures/Screenshots/` - Screenshot storage
- `~/Videos/Recordings/` - Screen recording storage

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
│   │       ├── Utilities.qml
│   │       ├── UtilityButton.qml
│   │       ├── RecordingButton.qml
│   │       └── RecordingState.qml  # Singleton recording state + IPC
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
│   ├── launcher/
│   │   ├── LauncherState.qml    # Singleton launcher state + IPC
│   │   ├── LauncherWindow.qml   # Launcher overlay window
│   │   ├── LauncherEntry.qml    # Search input with evaluators
│   │   ├── ResultItem.qml       # Search result item
│   │   ├── WindowResultItem.qml # Window result with live preview
│   │   ├── Evaluator.qml        # Evaluator manager
│   │   ├── results/             # Search providers
│   │   │   ├── AppResults.qml
│   │   │   ├── CommandResults.qml
│   │   │   ├── SystemResults.qml
│   │   │   └── WindowResults.qml
│   │   └── evaluators/          # Instant evaluators
│   │       ├── MathEvaluator.qml
│   │       ├── PercentageEvaluator.qml
│   │       ├── UnitEvaluator.qml
│   │       ├── BaseEvaluator.qml
│   │       ├── TimeEvaluator.qml
│   │       └── ColorEvaluator.qml
│   ├── notifications/
│   │   ├── NotificationServer.qml  # Singleton notification daemon
│   │   └── NotificationPopups.qml  # Popup windows
│   └── overview/
│       ├── Overview.qml          # Main overview entry with IPC
│       ├── OverviewState.qml     # Singleton state
│       ├── OverviewWidget.qml    # Workspace grid layout
│       ├── OverviewWindow.qml    # Individual window preview
│       └── HyprlandData.qml      # Hyprctl data singleton
├── services/
│   ├── BluetoothService.qml     # Bluetooth device management singleton
│   ├── CavaService.qml          # Audio visualization (cava) singleton
│   └── IconService.qml          # Centralized NerdFont icon mappings
├── scripts/
│   └── screen-capture.sh        # Screenshot and recording script
└── README.md
```

## Configuration

### Environment Variables

```bash
# Set max network speed for system resources (in Mbps)
export QS_NET_SPEED_MBPS=930
```

### Keybindings (Hyprland)

Add to your `hyprland.conf`:

```conf
# Toggle launcher
bind = SUPER, Space, exec, qs ipc call launcher toggle

# Toggle overview
bind = SUPER, Tab, exec, qs ipc call overview toggle

# Toggle right sidebar
bind = SUPER, N, exec, qs ipc call sidebar toggleRight

# Toggle left sidebar
bind = SUPER, T, exec, qs ipc call sidebar toggleLeft

# Screen capture
bind = , Print, exec, qs ipc call recording toggle
bind = SUPER, Print, exec, /path/to/faiyt-qs/scripts/screen-capture.sh screenshot selection
```

Or use the bar's utility buttons for quick access.

### IPC Commands

The shell exposes IPC handlers for external control:

```bash
# Launcher
qs ipc call launcher toggle      # Toggle launcher
qs ipc call launcher show        # Show launcher
qs ipc call launcher hide        # Hide launcher
qs ipc call launcher search "firefox"  # Open with search query

# Sidebars
qs ipc call sidebar toggleLeft   # Toggle left sidebar
qs ipc call sidebar toggleRight  # Toggle right sidebar
qs ipc call sidebar closeAll     # Close all sidebars

# Screen Recording
qs ipc call recording toggle     # Toggle recording (start selection/stop)
qs ipc call recording start selection  # Start recording selected area
qs ipc call recording start eDP-1      # Start recording primary display
qs ipc call recording stop       # Stop current recording
qs ipc call recording status     # Check if recording (returns "recording" or "idle")
qs ipc call recording setMode record      # Set to standard mode
qs ipc call recording setMode record-hq   # Set to high quality mode
qs ipc call recording setMode record-gif  # Set to GIF mode
qs ipc call recording getMode    # Get current recording mode

# Overview
qs ipc call overview toggle      # Toggle overview mode
qs ipc call overview open        # Open overview
qs ipc call overview close       # Close overview

# System Resources
qs ipc call sysresources setNetSpeed 930  # Set max network speed in Mbps
qs ipc call sysresources getNetSpeed      # Get current max network speed
```

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
- `busctl` - D-Bus queries (AccountsService for profile picture)
- `wpctl` / Pipewire - Audio control
- `systemctl` - Power management, idle inhibit
- `hyprctl` - Workspace management
- Standard Unix utilities (`uptime`, `whoami`, `hostname`, `id`, etc.)

## Credits

- [QuickShell](https://quickshell.outfoxxed.me/) - The shell framework
- [Rosé Pine](https://rosepinetheme.com/) - Color theme
- [Nerd Fonts](https://www.nerdfonts.com/) - Icon font

## License

MIT
