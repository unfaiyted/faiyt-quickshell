# faiyt-qs

A feature-rich QuickShell desktop shell for Hyprland, featuring a top bar and dual sidebars with the Rosé Pine color theme.

## Features

### Top Bar
- **Clock** - Time display with click to open calendar
- **Workspaces** - Hyprland workspace indicators with:
  - Configurable workspaces per page (default 10, adjustable 3-20)
  - Automatic paging when navigating beyond visible range
  - Click to switch workspace
  - Hover for live window preview tooltip
  - Click windows in tooltip to focus them
  - Middle-click windows to close them
- **Window Title** - Active window name with app icon
- **Mic Mute Indicator** - Shows when microphone is muted (click to unmute)
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
  - Left-click to focus app window (including Electron apps like Slack, Discord)
  - Right-click for context menu
- **Network** - Connection status indicator
- **Weather** - Current weather display
- **Utilities** - Quick action buttons with tooltips:
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
- Settings button (opens Settings Panel)
- Power button

**Quick Toggles (2x3 Grid):**
- WiFi on/off
- Bluetooth on/off
- Caffeine mode (idle inhibitor) / Focus Mode (optional)
- Microphone mute toggle
- Night Light (hyprsunset integration)
- VPN toggle (nmcli) / Power Saver (optional)

**Optional Toggles (configurable in Settings):**
- Focus Mode - Enables DND + Caffeine + switches bar to focus mode
- Power Saver - Toggles between balanced and power-saver profiles

### Left Sidebar
Dual-purpose panel with AI Chat and Developer Tools:

**AI Chat Tab:**
- **Claude Integration** - Chat with Claude AI (Anthropic)
- **Markdown Rendering** - Full markdown support in responses:
  - Headers, bold, italic, strikethrough
  - Bullet and numbered lists
  - Inline code with styling
  - Code blocks with syntax highlighting (JS, Python, Bash, Rust, Go, C++, QML, CSS, JSON)
  - Links, blockquotes, horizontal rules
- **Code Blocks** - Language detection, line numbers, one-click copy
- **Conversation Management** - Save, rename, delete conversations
- **Model Selection** - Switch between Claude models (Sonnet 4.5, Haiku 4.5, Opus 4.5)
- **Streaming Responses** - Real-time response streaming with typing indicator
- **Collapsible Conversation Sidebar** - Quick access to chat history

**Developer Tools Tab:**
Categories: All, Dev, System, Network, Monitor

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

### Settings Panel
Full-featured settings overlay for customizing the shell:

**Sections:**
- **Appearance** - Theme selector with live preview, bar mode, workspaces per page, display settings
- **Bar Modules** - Toggle individual bar modules (Window Title, Workspaces, Mic Indicator, System Resources, Utilities, Music, System Tray, Network, Battery, Clock, Weather)
- **Quick Toggles** - Configure sidebar quick toggles:
  - Enable Focus Mode toggle (replaces Caffeine)
  - Enable Power Saver toggle (replaces VPN)
  - VPN connection name for nmcli
  - Night Light color temperature (2500K-6500K)
- **Utility Buttons** - Toggle individual utility buttons (Screenshot, Recording, Color Picker, Wallpaper)
- **System Resources** - Toggle individual resource indicators (RAM, Swap, CPU, Download, Upload)
- **Default Modes** - Set default recording mode (Standard/High Quality/GIF) and screenshot mode (Screenshot/Annotate)
- **Time & Weather** - Time format, weather city, temperature unit (C/F)
- **Search/Launcher** - Max results, feature toggles (actions, commands, math results, directory search, AI search, web search)
- **Search Evaluators** - Toggle individual evaluators (math, base converter, color, date/time, percentage, units)
- **Battery** - Low and critical battery thresholds
- **Animations** - Duration and choreography delay
- **Windows & Components** - Enable/disable bar, corners, launcher, sidebars, overlays, notifications
- **Overview** - Configure items per row and total items shown in overview grid

**Features:**
- Searchable settings (type to filter)
- Theme preview with color swatches and "Customize" button to open Theme Manager
- All settings persist to JSON configuration at `~/.config/faiyt-qs/config.json`
- All settings apply immediately without restart
- ESC or click outside to close
- Smooth open/close animations

### Theme Manager
Full-featured theme editor for creating and customizing themes:

**Features:**
- **Built-in Themes** - Three Rosé Pine variants (Dark, Moon, Dawn)
- **Custom Themes** - Create new themes or duplicate existing ones
- **Live Editing** - Changes apply in real-time across all UI components
- **Full Color Palette** - Edit all 30 theme colors organized by category:
  - Base colors (base, surface, overlay)
  - Text colors (text, muted, subtle)
  - Accent colors (love, gold, rose, pine, foam, iris)
  - Semantic colors (primary, secondary, accent, success, warning, error, info)
  - UI component colors (background, foreground, border variants)
  - State colors (hover, active, focus, disabled)
- **HSL Color Picker** - Intuitive sliders for hue, saturation, and lightness
- **Hex Input** - Direct hex color code entry
- **Theme Metadata** - Edit display name and description
- Custom themes persist to `~/.config/faiyt-qs/config.json`

### Monitor Configuration
Visual monitor arrangement and configuration panel:

**Features:**
- Drag-and-drop monitor positioning with edge snapping
- Visual representation of monitor layout at scale
- Resolution and refresh rate selection
- Scale factor configuration (1x, 1.25x, 1.5x, 2x, etc.)
- Transform/rotation options (0°, 90°, 180°, 270°, flipped variants)
- Auto-align monitors in a row
- Apply, Reset, and Auto-align buttons

**Access:**
- Settings panel → Appearance → "Open Display Settings" button
- IPC: `qs ipc call monitors toggle`

### Launcher
Application launcher with instant evaluators and multiple search modes:

**Search Types:**
- **Apps** (`app:`, `a:`) - Search and launch desktop applications
- **Windows** (`win:`, `window:`, `w:`) - Search open windows with live previews
- **Commands** (`cmd:`, `$:`, `>:`) - Run shell commands with history
- **System** (`sys:`) - Power actions (shutdown, reboot, suspend, lock, logout)
- **Emoji** (`emoji:`, `e:`) - Search and copy emojis with keyword matching
- **Stickers** (`sticker:`, `st:`, `s:`) - Signal sticker packs with grid view
- **GIFs** (`gif:`, `g:`) - Search and copy GIFs via Tenor API
- **Tmux** (`tmux:`, `t:`) - Search and attach to tmux sessions in kitty terminal

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
| Date | `today + 30 days`, `days until dec 25` | Date calculations |
| Hash | `hash hello`, `md5 hello` | MD5, SHA1, SHA256 hashes |
| UUID | `uuid`, `uuid4` | Generate random UUID |
| Password | `password 16`, `pass 12` | Generate secure password |
| Lorem | `lorem 3`, `lorem 50 words` | Generate placeholder text |

**Features:**
- Press Enter to copy evaluator result to clipboard
- Click on result to copy
- Color swatch preview for color conversions
- "Copied!" feedback animation

**Keyboard Navigation:**
- `↑`/`↓` or `Ctrl+K`/`Ctrl+J` - Navigate results
- `←`/`→` - Navigate grid items (emoji, stickers, GIFs)
- `Enter` - Activate selected / Copy eval result
- `Escape` - Close launcher

**Emoji Search** (`e:` or `emoji:`):
- Grid view with 6 columns
- Search by emoji name or keywords (e.g., `e:smile`, `e:heart`, `e:fire`)
- Click or press Enter to copy emoji to clipboard
- Keyboard navigation with arrow keys

**Signal Stickers** (`s:`, `st:`, or `sticker:`):
- Browse and search Signal sticker packs
- Grid view with large preview panel
- Pack selection bar with keyboard navigation (Up arrow to focus, Left/Right to navigate, Enter to select)
- Search by emoji or pack name
- Click or press Enter to copy sticker image to clipboard
- **Adding Packs**: Via Settings → Launcher → Sticker Packs, or type `s: add <signal-url>` in launcher. Get URLs from [signalstickers.org](https://signalstickers.org) (right-click "Add to Signal" → Copy link)
- Stickers are decrypted and cached locally at `~/.cache/faiyt-qs/stickers/`
- Pack configuration stored in `~/.config/faiyt-qs/config.json`

**GIF Search** (`g:` or `gif:`):
- Search GIFs via Tenor API
- Grid view with 4 columns and animated previews
- Category tabs: Trending, Reactions, Memes, Animals, Anime, Sports
- Click or press Enter to copy GIF to clipboard
- Requires `TENOR_API_KEY` environment variable

**Tmux Sessions** (`t:` or `tmux:`):
- List all tmux windows across all sessions
- Shows window name, session context, and attached status
- Click or press Enter to attach in a new kitty terminal
- Type a new name to create a fresh tmux session
- Icons indicate active windows and attached sessions
- Can be disabled in Settings → Search Features → Tmux Sessions

**Quick Actions** (no prefix needed):
Quick actions appear in unified search alongside apps, providing fast access to:
- **Panel Shortcuts** - Settings, Display Settings, Theme Settings, Wallpaper, Overview
- **Bar Mode Switching** - Normal, Focus, Hidden modes
- **Media Controls** - Play/Pause, Next, Previous, Stop (only when media player active)
- **System Toggles** - WiFi, Bluetooth, Mic Mute, Night Light, VPN, Caffeine, Do Not Disturb
  - Toggles show current state (e.g., "WiFi: On" vs "WiFi: Off")
  - Icons update to reflect current state

**Usage Tracking & Smart Sorting**:
The launcher learns from your usage patterns:
- Items you select are tracked with frequency and recency
- Frequently and recently used items appear higher in results
- Uses logarithmic frequency scaling (prevents overused items from dominating)
- Recency decays over ~1 week half-life
- Stats stored in `~/.local/share/faiyt-qs/usage-stats.json`

### Screen Capture
Screenshot and screen recording functionality with area selection:

**Screenshots:**
- Left-click the screenshot button to take a screenshot
- Right-click to select screenshot mode before capturing:
  - **Screenshot** - Regular screenshot (copies to clipboard, shows notification)
  - **Screenshot + Annotate** - Opens screenshot in napkin for annotation (fullscreen)
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

- **Configurable Workspace Grid** - Default 2x5 (10 workspaces), configurable in Settings
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

### Keyboard Hint Navigation
Flash.nvim-style keyboard navigation for all clickable UI elements:

**Activation:**
- Press `Ctrl+Space` to activate hint mode in any panel
- Letter badges appear on all clickable elements
- Type the letter(s) to click the element
- Press `Escape` to cancel

**Supported Panels:**
- **Sidebars** - All tabs, toggles, buttons, and controls
- **Settings Panel** - All toggles, dropdowns, number inputs, and action buttons
- **Theme Manager** - Theme cards, color swatches, tab buttons, and font pickers
- **Monitor Configuration** - Monitor items, resolution/scale buttons, and action buttons
- **Wallpaper Picker** - Wallpaper items and navigation
- **Top Bar** - All interactive bar modules

**Features:**
- Scope-aware hints (only shows elements relevant to current panel)
- Single-letter hints (A-Z) for common elements
- Two-letter hints (AA-ZZ) when more elements are present
- Visual feedback with colored badges
- Automatic deactivation after action or panel close

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
- `napkin` - Image annotation tool (optional, for screenshot annotation)

**Quick Toggles Dependencies:**
- `hyprsunset` - Hyprland night light / blue light filter (optional)
- `powerprofilesctl` - Power profile switching (optional)

**Music Visualization:**
- `cava` - Audio visualizer for animated bars in the music module

**Sticker Support:**
- `openssl` - For Signal sticker decryption (AES-256-CBC)
- `python3` - For parsing protobuf manifests
- `curl` - For downloading stickers from Signal CDN
- `imagemagick` or `ffmpeg` - For WebP to PNG conversion

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
│   ├── Colors.qml               # Dynamic color bindings to ThemeService
│   ├── ThemeDefinitions.qml     # Built-in Rose Pine theme definitions
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
│   │       ├── MicIndicator.qml
│   │       ├── SystemResources.qml
│   │       ├── Battery.qml
│   │       ├── Music.qml
│   │       ├── SystemTray.qml
│   │       ├── Network.qml
│   │       ├── Weather.qml
│   │       ├── Utilities.qml
│   │       ├── UtilityButton.qml
│   │       ├── ScreenshotButton.qml  # Screenshot with annotation menu
│   │       ├── ScreenshotState.qml   # Singleton screenshot state
│   │       ├── RecordingButton.qml
│   │       └── RecordingState.qml    # Singleton recording state + IPC
│   ├── sidebar/
│   │   ├── SidebarState.qml     # Shared sidebar state
│   │   ├── SidebarOverlay.qml   # Click-away overlay
│   │   ├── SidebarLeft.qml      # Left sidebar panel
│   │   ├── SidebarRight.qml     # Right sidebar panel
│   │   ├── AIState.qml          # AI chat state singleton
│   │   └── modules/
│   │       ├── Header.qml
│   │       ├── QuickToggles.qml
│   │       ├── TabBar.qml
│   │       ├── LeftTabBar.qml   # AI/Tools tab switcher
│   │       ├── Notifications.qml
│   │       ├── AudioControl.qml
│   │       ├── BluetoothPanel.qml
│   │       ├── WiFiPanel.qml
│   │       ├── Calendar.qml
│   │       ├── Tools.qml
│   │       ├── ToolItem.qml
│   │       └── ai/              # AI chat components
│   │           ├── AIPanel.qml
│   │           ├── AISettings.qml
│   │           ├── AITabBar.qml
│   │           ├── ChatContainer.qml
│   │           ├── ChatHeader.qml
│   │           ├── ChatInput.qml
│   │           ├── ChatMessage.qml
│   │           ├── ChatMessages.qml
│   │           ├── CodeBlock.qml
│   │           ├── ConversationSidebar.qml
│   │           ├── MessageContent.qml
│   │           ├── MarkdownParser.js
│   │           └── SyntaxHighlighter.js
│   ├── launcher/
│   │   ├── LauncherState.qml    # Singleton launcher state + IPC
│   │   ├── LauncherWindow.qml   # Launcher overlay window
│   │   ├── LauncherEntry.qml    # Search input with evaluators
│   │   ├── ResultItem.qml       # Search result item
│   │   ├── WindowResultItem.qml # Window result with live preview
│   │   ├── Evaluator.qml        # Evaluator manager
│   │   ├── QuickActionState.qml # Quick action toggle states
│   │   ├── EmojiGridView.qml    # Emoji grid display
│   │   ├── StickerGridView.qml  # Sticker grid with preview panel
│   │   ├── StickerPackBar.qml   # Sticker pack selection bar
│   │   ├── GifGridView.qml      # GIF grid with categories
│   │   ├── results/             # Search providers
│   │   │   ├── AppResults.qml
│   │   │   ├── CommandResults.qml
│   │   │   ├── SystemResults.qml
│   │   │   ├── WindowResults.qml
│   │   │   ├── EmojiResults.qml     # Emoji search provider
│   │   │   ├── StickerResults.qml   # Signal sticker search
│   │   │   ├── GifResults.qml       # Tenor GIF search
│   │   │   ├── TmuxResults.qml      # Tmux session search
│   │   │   └── QuickActionResults.qml # Quick actions (panels, toggles, media)
│   │   └── evaluators/          # Instant evaluators
│   │       ├── MathEvaluator.qml
│   │       ├── PercentageEvaluator.qml
│   │       ├── UnitEvaluator.qml
│   │       ├── BaseEvaluator.qml
│   │       ├── TimeEvaluator.qml
│   │       ├── ColorEvaluator.qml
│   │       ├── DateEvaluator.qml
│   │       ├── CurrencyEvaluator.qml
│   │       ├── HashEvaluator.qml
│   │       ├── LoremEvaluator.qml
│   │       ├── PasswordEvaluator.qml
│   │       └── UuidEvaluator.qml
│   ├── notifications/
│   │   ├── NotificationServer.qml  # Singleton notification daemon
│   │   └── NotificationPopups.qml  # Popup windows
│   ├── overview/
│   │   ├── Overview.qml          # Main overview entry with IPC
│   │   ├── OverviewState.qml     # Singleton state
│   │   ├── OverviewWidget.qml    # Workspace grid layout
│   │   ├── OverviewWindow.qml    # Individual window preview
│   │   └── HyprlandData.qml      # Hyprctl data singleton
│   ├── settings/
│   │   ├── SettingsWindow.qml    # Full-screen overlay
│   │   ├── SettingsPanel.qml     # Main panel with all sections
│   │   ├── SettingsState.qml     # Singleton state + IPC
│   │   ├── ThemeSelector.qml     # Theme picker with previews
│   │   ├── ThemePanel.qml        # Theme manager with editor
│   │   ├── ThemePanelWindow.qml  # Theme panel overlay window
│   │   ├── ThemePanelState.qml   # Theme panel state + IPC
│   │   └── components/           # Reusable settings components
│   │       ├── SettingsSection.qml
│   │       ├── SettingRow.qml
│   │       ├── ToggleSwitch.qml
│   │       ├── NumberInput.qml
│   │       ├── SettingsTextInput.qml
│   │       ├── DropdownSelect.qml
│   │       ├── ThemeCard.qml         # Theme list item with preview
│   │       ├── ThemeEditorView.qml   # Color editor layout
│   │       ├── ColorSection.qml      # Collapsible color group
│   │       └── ColorRow.qml          # Color swatch + hex input
│   ├── monitors/
│   │   ├── MonitorsWindow.qml    # Full-screen overlay
│   │   ├── MonitorsPanel.qml     # Main panel with canvas + settings
│   │   ├── MonitorsState.qml     # Singleton state + IPC
│   │   ├── MonitorCanvas.qml     # Monitor arrangement canvas
│   │   ├── MonitorItem.qml       # Draggable monitor representation
│   │   └── MonitorSettings.qml   # Resolution/scale/transform settings
│   └── common/
│       ├── HintTarget.qml        # Registers clickable element for hint navigation
│       └── HintOverlay.qml       # Renders hint badges over UI elements
├── services/
│   ├── BatteryService.qml       # Battery monitoring and notifications
│   ├── BluetoothService.qml     # Bluetooth device management singleton
│   ├── CavaService.qml          # Audio visualization (cava) singleton
│   ├── ClaudeService.qml        # Claude AI API integration
│   ├── ConfigService.qml        # Settings persistence (JSON config)
│   ├── ConversationManager.qml  # AI conversation storage (~/.local/share)
│   ├── FontService.qml          # System font discovery and configuration
│   ├── HintNavigationService.qml # Flash.nvim-style keyboard hint navigation
│   ├── IconService.qml          # Centralized NerdFont icon mappings
│   ├── StickerService.qml       # Signal sticker pack management
│   ├── ThemeService.qml         # Theme switching and custom theme management
│   └── UsageStatsService.qml    # Launcher usage tracking for smart sorting
├── scripts/
│   ├── screen-capture.sh        # Screenshot and recording script
│   ├── sticker-decrypt.sh       # Signal sticker decryption (HKDF + AES)
│   └── parse-sticker-manifest.py  # Protobuf manifest parser
└── README.md
```

## Configuration

### Environment Variables

```bash
# Set max network speed for system resources (in Mbps)
export QS_NET_SPEED_MBPS=930

# Claude AI API key (required for AI chat)
export ANTHROPIC_API_KEY=sk-ant-...

# Tenor API key (required for GIF search)
# Get one free at https://developers.google.com/tenor/guides/quickstart
export TENOR_API_KEY=your-tenor-api-key
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

# Toggle settings
bind = SUPER, Comma, exec, qs ipc call settings toggle

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

# Settings
qs ipc call settings toggle      # Toggle settings panel
qs ipc call settings open        # Open settings panel
qs ipc call settings close       # Close settings panel

# Monitor Configuration
qs ipc call monitors toggle      # Toggle monitor configuration
qs ipc call monitors open        # Open monitor configuration
qs ipc call monitors close       # Close monitor configuration

# System Resources
qs ipc call sysresources setNetSpeed 930  # Set max network speed in Mbps
qs ipc call sysresources getNetSpeed      # Get current max network speed
```

## Themes

The shell includes three built-in Rosé Pine themes and supports creating custom themes:

**Built-in Themes:**
- **Rosé Pine** (Dark) - Default theme
- **Rosé Pine Moon** - Darker variant
- **Rosé Pine Dawn** - Light variant

**Default Colors (Rosé Pine):**

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

Themes can be switched live without restart. Custom themes are stored in `~/.config/faiyt-qs/config.json`.

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
