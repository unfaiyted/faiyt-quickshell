# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

faiyt-qs is a feature-rich desktop shell for Hyprland built with QuickShell (Qt6 QML). It provides a top bar, dual sidebars, launcher, settings panel, overview mode, and notification system with the Rosé Pine color theme.

**Repository:** `https://github.com/unfaiyted/faiyt-quickshell.git`
**Runtime config:** `~/.config/faiyt-qs/config.json`

## Running the Shell

```bash
# From project directory
quickshell -p shell.qml

# From anywhere
quickshell -p /path/to/faiyt-qs/shell.qml
```

## Environment Variables

```bash
export ANTHROPIC_API_KEY=sk-ant-...    # Required for AI chat
export TENOR_API_KEY=...                # Required for GIF search
export QS_NET_SPEED_MBPS=930            # Max network speed for resource monitor
```

## IPC Commands

```bash
qs ipc call launcher toggle|show|hide|search "query"
qs ipc call sidebar toggleLeft|toggleRight|closeAll
qs ipc call settings toggle|open|close
qs ipc call overview toggle|open|close
qs ipc call monitors toggle|open|close
qs ipc call recording toggle|start|stop|setMode|getMode|status
qs ipc call sysresources setNetSpeed|getNetSpeed
qs ipc call indicators showIndicator "volume|brightness|keyboard"|hide|status
qs ipc call network refresh|refreshVpn|refreshPublicIp
```

## Architecture

### Entry Point
`shell.qml` - Creates ShellRoot with all top-level components (Bar, Sidebars, Launcher, etc.)

### Directory Structure
```
├── shell.qml                 # Main entry, imports all components
├── theme/                    # Color system
│   ├── Colors.qml            # Dynamic color properties bound to ThemeService
│   └── ThemeDefinitions.qml  # Built-in Rosé Pine variants
├── services/                 # Singleton services (business logic)
├── components/
│   ├── bar/                  # Top panel + modules/
│   ├── sidebar/              # Left (AI/Tools) + Right (Notifications/Audio/etc)
│   ├── launcher/             # App launcher + evaluators/ + results/
│   ├── settings/             # Settings panel + components/
│   ├── overview/             # Workspace overview grid
│   ├── notifications/        # Notification daemon + popups
│   ├── indicators/           # OSD overlays (volume, brightness, KB backlight)
│   ├── monitors/             # Display configuration
│   └── wallpaper/            # Wallpaper picker
└── scripts/                  # Bash/Python utilities
```

### Services (Singletons)
All services are singletons registered in `services/qmldir`:

| Service | Purpose |
|---------|---------|
| ConfigService | Settings persistence to `~/.config/faiyt-qs/config.json` |
| ThemeService | Theme switching, custom theme management |
| ClaudeService | Claude API with streaming responses |
| BluetoothService | Bluetooth device management via bluetoothctl |
| IconService | NerdFont icon mappings |
| StickerService | Signal sticker decryption and caching |
| ConversationManager | AI chat history persistence |
| MCPClient | Model Context Protocol server integration |
| CavaService | Audio visualization (cava) |
| FontService | Font configuration |
| BrightnessService | Screen brightness control via brightnessctl/sysfs |
| KeyboardBacklightService | Keyboard backlight control via sysfs |
| BookmarkService | Browser bookmark loading with favicon caching |
| NightLightService | Automatic night light scheduling via hyprsunset |
| NotificationHistoryService | Notification persistence to survive shell reloads |

### State Singletons
Component-specific state is managed by singletons within each component directory:
- `LauncherState.qml` - Launcher visibility, search query, IPC handler
- `SidebarState.qml` - Sidebar open/close state
- `SettingsState.qml` - Settings panel state + IPC
- `OverviewState.qml` - Overview visibility + IPC
- `RecordingState.qml` - Recording state + IPC
- `AIState.qml` - AI chat state (messages, current conversation)
- `IndicatorState.qml` - OSD indicator visibility, values, IPC handler

### IPC Pattern
Components expose IPC handlers for external control:
```qml
IpcHandler {
    target: "launcher"
    function toggle() { ... }
    function show() { ... }
}
```

## Key Patterns

### Module Registration (qmldir)
Each component directory has a `qmldir` file registering exports:
```
module components.bar
Bar 1.0 Bar.qml
singleton RecordingState 1.0 modules/RecordingState.qml
```

### Theme Binding
Colors.qml properties bind to ThemeService for live updates:
```qml
readonly property color base: ThemeService.currentTheme?.colors?.base ?? "#191724"
```

### Process Execution
Use `Quickshell.Io.Process` for shell commands:
```qml
Process {
    id: myProcess
    command: ["bash", "-c", "your-command"]
    stdout: SplitParser { onRead: data => console.log(data) }
}
```

### Config Access
```qml
import "services" as Services
// Read
Services.ConfigService.getValue("bar.modules.clock", true)
// Write
Services.ConfigService.setValue("theme", "rose-pine-moon")
```

### System Resources Configuration
The SystemResources bar module supports toggleable indicators via `bar.systemResources.*`:

| Config Path | Default | Description |
|-------------|---------|-------------|
| `bar.systemResources.ram` | true | RAM usage indicator |
| `bar.systemResources.swap` | true | Swap usage indicator |
| `bar.systemResources.cpu` | true | CPU usage indicator |
| `bar.systemResources.download` | true | Network download speed |
| `bar.systemResources.upload` | true | Network upload speed |
| `bar.systemResources.gpu` | false | NVIDIA GPU usage (requires nvidia-smi) |
| `bar.systemResources.gpuTemp` | false | NVIDIA GPU temperature |
| `bar.systemResources.cpuTemp` | false | CPU temperature (via hwmon sysfs) |

Temperature indicators use color coding: green (<60°C), yellow (60-80°C), red (>80°C).
GPU indicators auto-hide if nvidia-smi is not available.

## Adding New Features

### New Bar Module
1. Create `components/bar/modules/MyModule.qml`
2. Add to `components/bar/modules/qmldir`
3. Add config toggle in `ConfigService.defaultConfig.bar.modules`
4. Use in Bar.qml with visibility bound to config

### New Launcher Evaluator
1. Create `components/launcher/evaluators/MyEvaluator.qml`
2. Add to `components/launcher/evaluators/qmldir`
3. Add config toggle in `ConfigService.defaultConfig.search.evaluators`
4. Register in `Evaluator.qml` evaluators array

### New Launcher Result Provider
1. Create `components/launcher/results/MyResults.qml`
2. Add to `components/launcher/results/qmldir`
3. Add prefix in `LauncherState.qml` prefixes object
4. Add instance and search routing in `LauncherState.qml`
5. Add config toggle in `ConfigService.defaultConfig.search.enableFeatures`

### Launcher Search Prefixes
| Prefix | Description |
|--------|-------------|
| `app:` `a:` | Search applications |
| `win:` `w:` | Search open windows |
| `cmd:` `$:` | Run shell command |
| `emoji:` `:` | Emoji picker |
| `sticker:` `s:` | Signal stickers |
| `gif:` `g:` | GIF search (Tenor) |
| `tmux:` `t:` | Tmux sessions/windows |
| `bookmark:` `bm:` `b:` | Browser bookmarks |
| `sys:` | System actions |
| `?` | List all prefixes |

### New Service
1. Create `services/MyService.qml` with `pragma Singleton`
2. Add to `services/qmldir`: `singleton MyService 1.0 MyService.qml`
3. Import and use: `import "services" as Services`

## Dependencies

**Core:** QuickShell, Hyprland, Symbols Nerd Font, wl-clipboard, Pipewire
**Screen Capture:** grim, slurp, wf-recorder, hyprpicker, napkin (annotation)
**Quick Toggles:** hyprsunset (night light), powerprofilesctl
**Brightness:** brightnessctl (for screen and keyboard backlight control)
**GPU Monitoring:** nvidia-utils (provides nvidia-smi for NVIDIA GPUs)
**Music:** cava (visualization)
**Stickers:** openssl, python3, curl, imagemagick/ffmpeg
**Bookmarks:** sqlite3, curl (for Firefox/Zen Browser bookmark search and favicon fetching)

## Legacy Reference

The original AGS implementation at `~/.config/ags/` serves as reference for style patterns and feature logic when implementing new components.
