#!/bin/bash
#
# faiyt-qs uninstaller
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/faiyt-qs"
FAIYT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/faiyt-qs"
INSTALL_NAME="faiyt-qs"

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              faiyt-qs Uninstaller                     ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Remove symlink
if [ -L "$CONFIG_DIR/$INSTALL_NAME" ]; then
    info "Removing symlink: $CONFIG_DIR/$INSTALL_NAME"
    rm "$CONFIG_DIR/$INSTALL_NAME"
    success "Symlink removed"
elif [ -d "$CONFIG_DIR/$INSTALL_NAME" ]; then
    warn "Found directory (not symlink) at $CONFIG_DIR/$INSTALL_NAME"
    read -p "Remove it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR/$INSTALL_NAME"
        success "Directory removed"
    fi
else
    info "No installation found at $CONFIG_DIR/$INSTALL_NAME"
fi

# Ask about config data
if [ -d "$FAIYT_CONFIG_DIR" ]; then
    echo ""
    warn "Found config directory: $FAIYT_CONFIG_DIR"
    echo "  This contains your settings, themes, and sticker packs."
    read -p "Remove config data? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$FAIYT_CONFIG_DIR"
        success "Config directory removed"
    else
        info "Config preserved at $FAIYT_CONFIG_DIR"
    fi
fi

# Ask about app data
if [ -d "$DATA_DIR" ]; then
    echo ""
    warn "Found data directory: $DATA_DIR"
    echo "  This contains usage statistics and conversation history."
    read -p "Remove app data? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DATA_DIR"
        success "Data directory removed"
    else
        info "Data preserved at $DATA_DIR"
    fi
fi

# Ask about sticker cache
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/faiyt-qs"
if [ -d "$CACHE_DIR" ]; then
    echo ""
    info "Found cache directory: $CACHE_DIR"
    read -p "Remove cache (stickers, etc.)? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        rm -rf "$CACHE_DIR"
        success "Cache removed"
    fi
fi

# Remove from hyprland.conf
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRLAND_CONF" ]; then
    if grep -q "faiyt-qs" "$HYPRLAND_CONF"; then
        echo ""
        warn "Found faiyt-qs references in hyprland.conf"
        read -p "Remove from hyprland.conf? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create backup
            cp "$HYPRLAND_CONF" "$HYPRLAND_CONF.bak"
            # Remove faiyt-qs related lines
            sed -i '/faiyt-qs/d' "$HYPRLAND_CONF"
            sed -i '/# faiyt-qs/d' "$HYPRLAND_CONF"
            success "Removed from hyprland.conf (backup at $HYPRLAND_CONF.bak)"
        fi
    fi
fi

echo ""
echo -e "${GREEN}Uninstall complete!${NC}"
echo ""
echo "Note: Dependencies installed via your package manager were not removed."
echo "To remove them manually:"
echo "  Arch:   pacman -Rns <package>"
echo "  Fedora: dnf remove <package>"
