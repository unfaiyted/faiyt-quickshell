# faiyt-qs

A QuickShell-based desktop bar for Hyprland using the Rosé Pine color theme.

## Requirements

- [QuickShell](https://quickshell.org/)
- Wayland compositor (Hyprland recommended)

## Running

```bash
quickshell -p shell.qml
```

Or from anywhere:

```bash
quickshell -p /home/faiyt/codebase/faiyt-qs/shell.qml
```

## Project Structure

```
faiyt-qs/
├── shell.qml           # Main entry point
├── components/
│   └── Bar.qml         # Top bar panel window
└── theme/
    ├── Colors.qml      # Rosé Pine color definitions
    └── qmldir          # QML module definition
```

## Colors (Rosé Pine)

| Color   | Hex       | Usage            |
|---------|-----------|------------------|
| base    | #191724   | Main background  |
| surface | #1f1d2e   | Elevated surfaces|
| overlay | #26233a   | Borders, groups  |
| text    | #e0def4   | Primary text     |
| iris    | #c4a7e7   | Primary accent   |
| love    | #eb6f92   | Error/accent     |
| gold    | #f6c177   | Warning          |
| foam    | #9ccfd8   | Success          |
| pine    | #31748f   | Info             |
