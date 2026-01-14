# Maintainer: Your Name <your.email@example.com>
pkgname=faiyt-qs
pkgver=1.0.0
pkgrel=1
pkgdesc="Feature-rich QuickShell desktop shell for Hyprland with Rosé Pine theme"
arch=('any')
url="https://github.com/unfaiyted/faiyt-quickshell"
license=('MIT')
depends=(
    # Core - Required
    'quickshell'
    'hyprland'
    'bash'

    # Clipboard - Required
    'wl-clipboard'

    # Audio - Required
    'wireplumber'
    'pipewire'

    # Network - Required
    'networkmanager'
    'curl'

    # Bluetooth - Required
    'bluez-utils'

    # Power/System - Required
    'systemd'

    # System Info - Required
    'procps-ng'
    'coreutils'
    'inetutils'

    # Utilities - Required
    'xdg-utils'
    'grep'
    'gawk'
    'sed'

    # Fonts - Required
    'ttf-nerd-fonts-symbols'
)
optdepends=(
    # Audio visualization
    'cava: Audio visualizer for music module'

    # Screen capture
    'grim: Screenshots'
    'slurp: Area selection for screenshots/recording'
    'wf-recorder: Screen recording'
    'hyprpicker: Color picker'
    'napkin: Screenshot annotation'
    'imagemagick: Multi-monitor screenshots, image conversion'

    # Media processing
    'ffmpeg: Video/GIF conversion'

    # Signal stickers
    'openssl: Sticker decryption'
    'python: Sticker manifest parsing'

    # Font management
    'fontconfig: Font listing'

    # Quick toggles
    'hyprsunset: Night light / blue light filter'
    'power-profiles-daemon: Power profile switching'
    'wireguard-tools: WireGuard VPN support (wg-quick)'
    'polkit: Privilege escalation for VPN toggle (pkexec)'

    # Wallpaper
    'swww: Animated wallpaper daemon'

    # Terminals
    'kitty: Terminal emulator for tmux integration'
    'tmux: Terminal multiplexer integration'

    # Notifications
    'libnotify: Desktop notification support'
)
source=("git+${url}.git")
sha256sums=('SKIP')

package() {
    cd "$srcdir/faiyt-quickshell"

    # Install to /usr/share/faiyt-qs
    install -dm755 "$pkgdir/usr/share/$pkgname"

    # Copy all files
    cp -r shell.qml theme components services scripts "$pkgdir/usr/share/$pkgname/"

    # Make scripts executable
    chmod +x "$pkgdir/usr/share/$pkgname/scripts/"*.sh
    chmod +x "$pkgdir/usr/share/$pkgname/scripts/"*.py 2>/dev/null || true

    # Install documentation
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 CLAUDE.md "$pkgdir/usr/share/doc/$pkgname/CLAUDE.md"

    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE" 2>/dev/null || \
        echo "MIT License" > "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

    # Create symlink in quickshell config location
    install -dm755 "$pkgdir/usr/share/quickshell"
    ln -sf "/usr/share/$pkgname" "$pkgdir/usr/share/quickshell/$pkgname"

    # Install wrapper script
    install -Dm755 /dev/stdin "$pkgdir/usr/bin/$pkgname" << 'EOF'
#!/bin/bash
# faiyt-qs launcher wrapper
exec quickshell -p /usr/share/faiyt-qs/shell.qml "$@"
EOF

    # Install desktop entry (optional - for display managers)
    install -Dm644 /dev/stdin "$pkgdir/usr/share/wayland-sessions/$pkgname.desktop" << EOF
[Desktop Entry]
Name=faiyt-qs (Hyprland)
Comment=QuickShell desktop shell for Hyprland
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
}

post_install() {
    echo ""
    echo "==> faiyt-qs installed!"
    echo ""
    echo "To use faiyt-qs, add to your hyprland.conf:"
    echo "  exec-once = faiyt-qs"
    echo ""
    echo "Or run directly:"
    echo "  faiyt-qs"
    echo ""
    echo "Optional: Set environment variables in your shell profile:"
    echo "  export ANTHROPIC_API_KEY=sk-ant-...  # For AI chat"
    echo "  export TENOR_API_KEY=...             # For GIF search"
    echo ""
}

post_upgrade() {
    post_install
}
