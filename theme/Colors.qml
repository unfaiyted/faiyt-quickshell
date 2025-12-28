pragma Singleton
import QtQuick

QtObject {
    // Base Colors (Rosé Pine)
    readonly property color base: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"

    // Text Colors
    readonly property color text: "#e0def4"
    readonly property color muted: "#6e6a86"
    readonly property color subtle: "#908caa"

    // Accent Colors
    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ebbcba"
    readonly property color pine: "#31748f"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"

    // Semantic Color Roles
    readonly property color primary: iris
    readonly property color secondary: pine
    readonly property color accent: love
    readonly property color success: foam
    readonly property color warning: gold
    readonly property color error: love
    readonly property color info: pine

    // UI Component Colors
    readonly property color background: base
    readonly property color backgroundAlt: surface
    readonly property color backgroundElevated: overlay
    readonly property color foreground: text
    readonly property color foregroundAlt: subtle
    readonly property color foregroundMuted: muted
    readonly property color border: overlay
    readonly property color borderAlt: muted

    // State Colors
    readonly property color hover: overlay
    readonly property color active: "#393552"
    readonly property color focus: iris
    readonly property color disabled: muted
}
