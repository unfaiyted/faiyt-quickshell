#!/bin/bash
#
# faiyt-qs installer
# Supports: Arch Linux, Fedora
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
INSTALL_NAME="faiyt-qs"

print_header() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║              faiyt-qs Installer                       ║"
    echo "║     QuickShell Desktop Shell for Hyprland             ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    else
        DISTRO="unknown"
    fi
    echo "$DISTRO"
}

# Package mappings for different distros
declare -A ARCH_PACKAGES=(
    # Core - Required
    ["quickshell"]="quickshell"
    ["hyprctl"]="hyprland"
    ["bash"]="bash"

    # Clipboard - Required
    ["wl-copy"]="wl-clipboard"
    ["wl-paste"]="wl-clipboard"

    # Audio
    ["wpctl"]="wireplumber"
    ["cava"]="cava"

    # Network - Required
    ["nmcli"]="networkmanager"
    ["curl"]="curl"

    # Bluetooth - Required
    ["bluetoothctl"]="bluez-utils"
    ["busctl"]="systemd"

    # Power - Required
    ["systemctl"]="systemd"
    ["systemd-inhibit"]="systemd"

    # Screen Capture
    ["grim"]="grim"
    ["slurp"]="slurp"
    ["wf-recorder"]="wf-recorder"
    ["hyprpicker"]="hyprpicker"
    ["napkin"]="napkin"
    ["montage"]="imagemagick"

    # Media
    ["ffmpeg"]="ffmpeg"
    ["ffprobe"]="ffmpeg"
    ["convert"]="imagemagick"

    # Stickers
    ["openssl"]="openssl"
    ["python3"]="python"

    # System Info - Required
    ["free"]="procps-ng"
    ["top"]="procps-ng"
    ["uptime"]="procps-ng"
    ["whoami"]="coreutils"
    ["hostname"]="inetutils"
    ["fc-list"]="fontconfig"

    # Quick Toggles
    ["hyprsunset"]="hyprsunset"
    ["powerprofilesctl"]="power-profiles-daemon"

    # Wallpaper
    ["swww"]="swww"

    # Terminals
    ["kitty"]="kitty"
    ["tmux"]="tmux"

    # Notifications
    ["notify-send"]="libnotify"

    # Utilities - Required
    ["pgrep"]="procps-ng"
    ["pkill"]="procps-ng"
    ["xdg-open"]="xdg-utils"
    ["grep"]="grep"
    ["awk"]="gawk"
    ["sed"]="sed"
)

declare -A FEDORA_PACKAGES=(
    # Core - Required
    ["quickshell"]="quickshell"
    ["hyprctl"]="hyprland"
    ["bash"]="bash"

    # Clipboard - Required
    ["wl-copy"]="wl-clipboard"
    ["wl-paste"]="wl-clipboard"

    # Audio
    ["wpctl"]="wireplumber"
    ["cava"]="cava"

    # Network - Required
    ["nmcli"]="NetworkManager"
    ["curl"]="curl"

    # Bluetooth - Required
    ["bluetoothctl"]="bluez"
    ["busctl"]="systemd"

    # Power - Required
    ["systemctl"]="systemd"
    ["systemd-inhibit"]="systemd"

    # Screen Capture
    ["grim"]="grim"
    ["slurp"]="slurp"
    ["wf-recorder"]="wf-recorder"
    ["hyprpicker"]="hyprpicker"
    ["napkin"]="napkin"
    ["montage"]="ImageMagick"

    # Media
    ["ffmpeg"]="ffmpeg"
    ["ffprobe"]="ffmpeg"
    ["convert"]="ImageMagick"

    # Stickers
    ["openssl"]="openssl"
    ["python3"]="python3"

    # System Info - Required
    ["free"]="procps-ng"
    ["top"]="procps-ng"
    ["uptime"]="procps-ng"
    ["whoami"]="coreutils"
    ["hostname"]="hostname"
    ["fc-list"]="fontconfig"

    # Quick Toggles
    ["hyprsunset"]="hyprsunset"
    ["powerprofilesctl"]="power-profiles-daemon"

    # Wallpaper
    ["swww"]="swww"

    # Terminals
    ["kitty"]="kitty"
    ["tmux"]="tmux"

    # Notifications
    ["notify-send"]="libnotify"

    # Utilities - Required
    ["pgrep"]="procps-ng"
    ["pkill"]="procps-ng"
    ["xdg-open"]="xdg-utils"
    ["grep"]="grep"
    ["awk"]="gawk"
    ["sed"]="sed"
)

# Required tools (must be installed)
REQUIRED_TOOLS=(
    "quickshell" "hyprctl" "bash"
    "wl-copy" "wl-paste"
    "wpctl"
    "nmcli" "curl"
    "bluetoothctl" "busctl"
    "systemctl" "systemd-inhibit"
    "free" "top" "uptime" "whoami" "hostname"
    "pgrep" "pkill" "xdg-open" "grep" "awk" "sed"
)

# Optional tools
OPTIONAL_TOOLS=(
    "cava"
    "grim" "slurp" "wf-recorder" "hyprpicker" "napkin" "montage"
    "ffmpeg" "ffprobe" "convert"
    "openssl" "python3"
    "fc-list"
    "hyprsunset" "powerprofilesctl"
    "swww"
    "kitty" "tmux"
    "notify-send"
)

check_tool() {
    command -v "$1" >/dev/null 2>&1
}

get_missing_packages() {
    local distro=$1
    local -n tool_list=$2
    local -n pkg_map=$3
    local missing=()

    for tool in "${tool_list[@]}"; do
        if ! check_tool "$tool"; then
            pkg="${pkg_map[$tool]}"
            if [ -n "$pkg" ] && [[ ! " ${missing[*]} " =~ " ${pkg} " ]]; then
                missing+=("$pkg")
            fi
        fi
    done

    echo "${missing[@]}"
}

install_arch() {
    info "Detected Arch Linux"

    # Check for AUR helper
    AUR_HELPER=""
    if check_tool "yay"; then
        AUR_HELPER="yay"
    elif check_tool "paru"; then
        AUR_HELPER="paru"
    fi

    # Get missing required packages
    local missing_required
    missing_required=$(get_missing_packages "arch" REQUIRED_TOOLS ARCH_PACKAGES)

    # Get missing optional packages
    local missing_optional
    missing_optional=$(get_missing_packages "arch" OPTIONAL_TOOLS ARCH_PACKAGES)

    if [ -n "$missing_required" ]; then
        echo ""
        warn "Missing required packages:"
        echo -e "  ${YELLOW}$missing_required${NC}"
        echo ""

        read -p "Install required packages? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if [ -n "$AUR_HELPER" ]; then
                info "Installing with $AUR_HELPER..."
                $AUR_HELPER -S --needed $missing_required
            else
                info "Installing with pacman (some packages may need AUR helper)..."
                sudo pacman -S --needed $missing_required 2>/dev/null || true
                warn "Some packages may need an AUR helper (yay/paru) to install"
            fi
        fi
    else
        success "All required packages are installed"
    fi

    if [ -n "$missing_optional" ]; then
        echo ""
        info "Missing optional packages (for extra features):"
        echo -e "  ${CYAN}$missing_optional${NC}"
        echo ""

        read -p "Install optional packages? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -n "$AUR_HELPER" ]; then
                $AUR_HELPER -S --needed $missing_optional
            else
                sudo pacman -S --needed $missing_optional 2>/dev/null || true
            fi
        fi
    fi
}

install_fedora() {
    info "Detected Fedora"

    # Check if COPR for quickshell is enabled
    if ! dnf copr list 2>/dev/null | grep -q "quickshell"; then
        warn "QuickShell COPR repository not enabled"
        read -p "Enable errornointernet/quickshell COPR? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            sudo dnf copr enable errornointernet/quickshell -y
        fi
    fi

    # Check if hyprland COPR is enabled
    if ! dnf copr list 2>/dev/null | grep -q "hyprland"; then
        warn "Hyprland COPR repository not enabled"
        read -p "Enable solopasha/hyprland COPR? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            sudo dnf copr enable solopasha/hyprland -y
        fi
    fi

    # Get missing required packages
    local missing_required
    missing_required=$(get_missing_packages "fedora" REQUIRED_TOOLS FEDORA_PACKAGES)

    # Get missing optional packages
    local missing_optional
    missing_optional=$(get_missing_packages "fedora" OPTIONAL_TOOLS FEDORA_PACKAGES)

    if [ -n "$missing_required" ]; then
        echo ""
        warn "Missing required packages:"
        echo -e "  ${YELLOW}$missing_required${NC}"
        echo ""

        read -p "Install required packages? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            info "Installing with dnf..."
            sudo dnf install -y $missing_required
        fi
    else
        success "All required packages are installed"
    fi

    if [ -n "$missing_optional" ]; then
        echo ""
        info "Missing optional packages (for extra features):"
        echo -e "  ${CYAN}$missing_optional${NC}"
        echo ""

        read -p "Install optional packages? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo dnf install -y $missing_optional
        fi
    fi
}

install_config() {
    info "Setting up faiyt-qs configuration..."

    # Create quickshell config directory if needed
    mkdir -p "$CONFIG_DIR"

    # Check if already installed
    if [ -L "$CONFIG_DIR/$INSTALL_NAME" ]; then
        warn "Symlink already exists at $CONFIG_DIR/$INSTALL_NAME"
        read -p "Replace it? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$CONFIG_DIR/$INSTALL_NAME"
        else
            return 0
        fi
    elif [ -d "$CONFIG_DIR/$INSTALL_NAME" ]; then
        warn "Directory already exists at $CONFIG_DIR/$INSTALL_NAME"
        read -p "Replace it? (existing config will be backed up) [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            backup_dir="$CONFIG_DIR/${INSTALL_NAME}.backup.$(date +%Y%m%d%H%M%S)"
            mv "$CONFIG_DIR/$INSTALL_NAME" "$backup_dir"
            info "Backed up to $backup_dir"
        else
            return 0
        fi
    fi

    # Create symlink
    ln -s "$SCRIPT_DIR" "$CONFIG_DIR/$INSTALL_NAME"
    success "Created symlink: $CONFIG_DIR/$INSTALL_NAME -> $SCRIPT_DIR"
}

setup_autostart() {
    local hyprland_conf="$HOME/.config/hypr/hyprland.conf"

    if [ -f "$hyprland_conf" ]; then
        if grep -q "quickshell.*faiyt-qs" "$hyprland_conf"; then
            success "Autostart already configured in hyprland.conf"
        else
            echo ""
            info "Add to Hyprland autostart?"
            echo "  This will add: exec-once = quickshell -c faiyt-qs"
            read -p "Add autostart? [Y/n] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                echo "" >> "$hyprland_conf"
                echo "# faiyt-qs shell" >> "$hyprland_conf"
                echo "exec-once = quickshell -c faiyt-qs" >> "$hyprland_conf"
                success "Added autostart to hyprland.conf"
            fi
        fi
    else
        warn "hyprland.conf not found at $hyprland_conf"
        info "Add this to your Hyprland config manually:"
        echo "  exec-once = quickshell -c faiyt-qs"
    fi
}

setup_keybindings() {
    local hyprland_conf="$HOME/.config/hypr/hyprland.conf"

    if [ -f "$hyprland_conf" ]; then
        if grep -q "qs ipc call launcher" "$hyprland_conf"; then
            success "Keybindings already configured"
            return 0
        fi

        echo ""
        info "Add recommended keybindings to Hyprland?"
        echo "  SUPER+Space  - Toggle launcher"
        echo "  SUPER+Tab    - Toggle overview"
        echo "  SUPER+N      - Toggle right sidebar"
        echo "  SUPER+T      - Toggle left sidebar"
        echo "  SUPER+,      - Toggle settings"
        read -p "Add keybindings? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            cat >> "$hyprland_conf" << 'EOF'

# faiyt-qs keybindings
bind = SUPER, Space, exec, qs ipc call launcher toggle
bind = SUPER, Tab, exec, qs ipc call overview toggle
bind = SUPER, N, exec, qs ipc call sidebar toggleRight
bind = SUPER, T, exec, qs ipc call sidebar toggleLeft
bind = SUPER, Comma, exec, qs ipc call settings toggle
EOF
            success "Added keybindings to hyprland.conf"
        fi
    fi
}

create_directories() {
    info "Creating required directories..."
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Videos/Recordings"
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/faiyt-qs"
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/faiyt-qs"
    success "Directories created"
}

print_post_install() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            Installation Complete!                     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "To start faiyt-qs:"
    echo -e "  ${CYAN}quickshell -c faiyt-qs${NC}"
    echo ""
    echo "Or if added to autostart, just reload Hyprland."
    echo ""
    echo "Optional environment variables (add to your shell profile):"
    echo -e "  ${YELLOW}export ANTHROPIC_API_KEY=sk-ant-...${NC}  # For AI chat"
    echo -e "  ${YELLOW}export TENOR_API_KEY=...${NC}             # For GIF search"
    echo -e "  ${YELLOW}export QS_NET_SPEED_MBPS=930${NC}         # Network speed calibration"
    echo ""
}

# Main
main() {
    print_header

    DISTRO=$(detect_distro)
    info "Detected distribution: $DISTRO"

    case "$DISTRO" in
        arch|endeavouros|manjaro|garuda)
            install_arch
            ;;
        fedora)
            install_fedora
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            echo "Supported: Arch Linux (and derivatives), Fedora"
            echo ""
            echo "You can still install manually:"
            echo "1. Install dependencies listed in README.md"
            echo "2. Symlink this directory to ~/.config/quickshell/faiyt-qs"
            echo "3. Run: quickshell -c faiyt-qs"
            exit 1
            ;;
    esac

    echo ""
    install_config
    create_directories
    setup_autostart
    setup_keybindings
    print_post_install
}

main "$@"
