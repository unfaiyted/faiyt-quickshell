pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: iconService

    // Current distro ID (detected from /etc/os-release)
    property string currentDistro: ""

    // Detect distro on startup
    Component.onCompleted: {
        distroProcess.running = true
    }

    Process {
        id: distroProcess
        command: ["bash", "-c", "grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '\"'"]
        stdout: SplitParser {
            onRead: data => {
                iconService.currentDistro = data.trim().toLowerCase()
                console.log("Detected distro:", iconService.currentDistro)
            }
        }
    }

    // Linux distribution icons (NerdFont - nf-linux-* and nf-md-*)
    readonly property var distroMap: ({
        "arch": "󰣇",
        "archlinux": "󰣇",
        "endeavouros": "󰣇",  // Arch-based, use Arch icon
        "manjaro": "󱘊",
        "artix": "󰣇",
        "arcolinux": "󰣇",
        "garuda": "󰣇",
        "ubuntu": "󰕈",
        "kubuntu": "󰕈",
        "xubuntu": "󰕈",
        "lubuntu": "󰕈",
        "pop": "󰕈",
        "popos": "󰕈",
        "pop_os": "󰕈",
        "mint": "󰣭",
        "linuxmint": "󰣭",
        "debian": "󰣚",
        "fedora": "󰣛",
        "centos": "󱄚",
        "rhel": "󰮤",
        "redhat": "󰮤",
        "opensuse": "󰣨",
        "opensuse-tumbleweed": "󰣨",
        "opensuse-leap": "󰣨",
        "suse": "󰣨",
        "gentoo": "󰣨",
        "void": "󰣨",
        "voidlinux": "󰣨",
        "nixos": "󱄅",
        "alpine": "󰣨",
        "kali": "󰣨",
        "parrot": "󰣨",
        "elementary": "󰣨",
        "elementaryos": "󰣨",
        "zorin": "󰣨",
        "zorinos": "󰣨",
        "solus": "󰣨",
        "mx": "󰣨",
        "mxlinux": "󰣨",
        "raspbian": "󰌽",
        "raspberry": "󰌽",
        "slackware": "󰣨",
        "devuan": "󰣚",
        "deepin": "󰣨",
        "clearlinux": "󰣨",
        "linux": "󰌽"  // Generic Linux/Tux fallback
    })

    // Get the icon for current distro
    function getDistroIcon() {
        if (!currentDistro) return distroMap["linux"]

        // Direct match
        if (distroMap.hasOwnProperty(currentDistro)) {
            return distroMap[currentDistro]
        }

        // Partial match
        for (let key in distroMap) {
            if (currentDistro.includes(key) || key.includes(currentDistro)) {
                return distroMap[key]
            }
        }

        return distroMap["linux"]
    }

    // Get icon for a specific distro name
    function getDistroIconByName(distroName) {
        if (!distroName) return distroMap["linux"]

        let lower = distroName.toLowerCase()

        if (distroMap.hasOwnProperty(lower)) {
            return distroMap[lower]
        }

        for (let key in distroMap) {
            if (lower.includes(key) || key.includes(lower)) {
                return distroMap[key]
            }
        }

        return distroMap["linux"]
    }

    // Comprehensive Nerd Font icon mappings for common apps
    readonly property var iconMap: ({
        // Browsers
        "firefox": "󰈹",
        "zen": "󰈹",
        "librewolf": "󰈹",
        "floorp": "󰈹",
        "chromium": "󰊯",
        "chrome": "󰊯",
        "google-chrome": "󰊯",
        "brave": "󰖟",
        "edge": "󰇩",
        "vivaldi": "󰖟",
        "opera": "󰀹",
        "qutebrowser": "󰖟",

        // Communication
        "signal": "󰭹",
        "discord": "󰙯",
        "goofcord": "󰙯",
        "legcord": "󰙯",
        "webcord": "󰙯",
        "armcord": "󰙯",
        "telegram": "󰔁",
        "slack": "󰒱",
        "teams": "󰊻",
        "element": "󰭻",
        "matrix": "󰭻",
        "thunderbird": "󰇮",
        "mailspring": "󰇮",
        "geary": "󰇮",

        // Media
        "spotify": "󰓇",
        "vlc": "󰕼",
        "mpv": "󰐌",
        "imv": "󰋩",
        "feh": "󰋩",
        "sxiv": "󰋩",
        "eog": "󰋩",
        "loupe": "󰋩",
        "gimp": "󰃣",
        "inkscape": "󰴒",
        "krita": "󰃣",
        "obs": "󰑋",
        "kdenlive": "�avi",
        "audacity": "󰝚",
        "rhythmbox": "󰓃",
        "lollypop": "󰓃",
        "amberol": "󰓃",
        "celluloid": "󰐌",
        "totem": "󰐌",

        // Gaming
        "steam": "󰓓",
        "lutris": "󰺵",
        "heroic": "󰺵",
        "bottles": "󱄮",
        "gamemode": "󰊖",
        "mangohud": "󰊖",

        // Development
        "code": "󰨞",
        "vscode": "󰨞",
        "codium": "󰨞",
        "vscodium": "󰨞",
        "neovim": "",
        "nvim": "",
        "vim": "",
        "emacs": "󰯸",
        "zed": "󰨞",
        "sublime": "󰅳",
        "atom": "󰊤",
        "jetbrains": "󰛓",
        "intellij": "󰛓",
        "pycharm": "󰌠",
        "webstorm": "󰛓",
        "android-studio": "󰀴",
        "postman": "󰛮",
        "insomnia": "󰛮",
        "dbeaver": "󰆼",
        "datagrip": "󰆼",

        // Terminals
        "kitty": "󰄛",
        "alacritty": "",
        "wezterm": "",
        "foot": "",
        "gnome-terminal": "",
        "konsole": "",
        "xterm": "",
        "urxvt": "",
        "st": "",
        "terminator": "",
        "tilix": "",
        "blackbox": "",

        // File managers
        "nautilus": "󰉋",
        "thunar": "󰉋",
        "dolphin": "󰉋",
        "nemo": "󰉋",
        "pcmanfm": "󰉋",
        "ranger": "󰉋",
        "yazi": "󰉋",
        "lf": "󰉋",

        // System / Settings
        "settings": "󰒓",
        "gnome-control-center": "󰒓",
        "systemsettings": "󰒓",
        "pavucontrol": "󰕾",
        "blueman": "󰂯",
        "nm-connection-editor": "󰤨",
        "gnome-disks": "󰋊",
        "gparted": "󰋊",
        "baobab": "󰋊",
        "htop": "󰍛",
        "btop": "󰍛",
        "mission-center": "󰍛",
        "resources": "󰍛",
        "gnome-system-monitor": "󰍛",

        // Office / Documents
        "libreoffice": "󰏆",
        "writer": "󰈙",
        "calc": "󰈛",
        "impress": "󰈩",
        "draw": "󰽉",
        "evince": "󰈦",
        "okular": "󰈦",
        "zathura": "󰈦",
        "foliate": "󰂿",
        "calibre": "󰂿",

        // Notes / Productivity
        "obsidian": "󱓧",
        "notion": "󱓧",
        "logseq": "󱓧",
        "joplin": "󱓧",
        "standard-notes": "󱓧",
        "simplenote": "󱓧",
        "todoist": "󰄬",
        "ticktick": "󰄬",

        // Utilities
        "flameshot": "󰹑",
        "spectacle": "󰹑",
        "screenshot": "󰹑",
        "napkin": "󰏬",
        "peek": "󰑋",
        "kooha": "󰑋",
        "wf-recorder": "󰑋",
        "bitwarden": "󰞀",
        "keepassxc": "󰞀",
        "1password": "󰞀",

        // Virtualization
        "virt-manager": "󰪫",
        "virtualbox": "󰪫",
        "vmware": "󰪫",
        "gnome-boxes": "󰪫",
        "qemu": "󰪫",

        // Social / Web
        "twitter": "󰕄",
        "mastodon": "󰫑",
        "reddit": "󰑍",
        "youtube": "󰗃",
        "twitch": "󰕃",

        // Misc
        "calculator": "󰃬",
        "gnome-calculator": "󰃬",
        "kcalc": "󰃬",
        "calendar": "󰃭",
        "gnome-calendar": "󰃭",
        "clock": "󰥔",
        "gnome-clocks": "󰥔",
        "weather": "󰖐",
        "gnome-weather": "󰖐",
        "maps": "󰍎",
        "gnome-maps": "󰍎",

        // Common symbolic icons (for menus)
        "bluetooth-symbolic": "󰂯",
        "bluetooth-disabled-symbolic": "󰂲",
        "bluetooth-active-symbolic": "󰂱",
        "edit-find-symbolic": "󰍉",
        "edit-find": "󰍉",
        "document-open-recent-symbolic": "󰋚",
        "document-open-recent": "󰋚",
        "audio-headset": "󰋋",
        "audio-headphones": "󰋋",
        "audio-speakers": "󰓃",
        "document-properties-symbolic": "󰈙",
        "document-properties": "󰈙",
        "application-x-addon-symbolic": "󰏓",
        "application-x-addon": "󰏓",
        "help-about-symbolic": "󰋗",
        "help-about": "󰋗",
        "application-exit-symbolic": "󰗼",
        "application-exit": "󰗼",
        "preferences-system-symbolic": "󰒓",
        "preferences-system": "󰒓",
        "list-add-symbolic": "󰐕",
        "list-add": "󰐕",
        "list-remove-symbolic": "󰍴",
        "list-remove": "󰍴",
        "view-refresh-symbolic": "󰑐",
        "view-refresh": "󰑐",
        "network-wireless-symbolic": "󰤨",
        "network-wired-symbolic": "󰈀",
        "network-offline-symbolic": "󰤮",
        "system-shutdown-symbolic": "󰐥",
        "system-reboot-symbolic": "󰜉",
        "system-log-out-symbolic": "󰍃",
        "user-trash-symbolic": "󰆴",
        "folder-symbolic": "󰉋",
        "emblem-system-symbolic": "󰒓",

        // Default fallback
        "default": "󰀻"
    })

    // Get NerdFont icon for an app name
    function getIcon(appName) {
        if (!appName) return iconMap["default"]

        let lower = appName.toLowerCase()

        // Direct match first
        if (iconMap.hasOwnProperty(lower)) {
            return iconMap[lower]
        }

        // Partial match (app name contains key)
        for (let key in iconMap) {
            if (key !== "default" && lower.includes(key)) {
                return iconMap[key]
            }
        }

        return iconMap["default"]
    }

    // Check if we have a specific icon for an app
    function hasIcon(appName) {
        if (!appName) return false

        let lower = appName.toLowerCase()

        if (iconMap.hasOwnProperty(lower)) return true

        for (let key in iconMap) {
            if (key !== "default" && lower.includes(key)) {
                return true
            }
        }

        return false
    }
}
