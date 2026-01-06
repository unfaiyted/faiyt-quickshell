Name:           faiyt-qs
Version:        1.0.0
Release:        1%{?dist}
Summary:        Feature-rich QuickShell desktop shell for Hyprland

License:        MIT
URL:            https://github.com/unfaiyted/faiyt-quickshell
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch

# Core - Required
Requires:       quickshell
Requires:       hyprland
Requires:       bash

# Clipboard - Required
Requires:       wl-clipboard

# Audio - Required
Requires:       wireplumber
Requires:       pipewire

# Network - Required
Requires:       NetworkManager
Requires:       curl

# Bluetooth - Required
Requires:       bluez

# Power/System - Required
Requires:       systemd

# System Info - Required
Requires:       procps-ng
Requires:       coreutils
Requires:       hostname

# Utilities - Required
Requires:       xdg-utils
Requires:       grep
Requires:       gawk
Requires:       sed

# Fonts
Requires:       google-noto-fonts-common

# Optional dependencies (Recommends in Fedora)
Recommends:     grim
Recommends:     slurp
Recommends:     wf-recorder
Recommends:     ImageMagick
Recommends:     ffmpeg
Recommends:     kitty
Recommends:     tmux
Recommends:     libnotify
Recommends:     openssl
Recommends:     python3
Recommends:     fontconfig

# Weak dependencies (nice to have)
Suggests:       cava
Suggests:       hyprpicker
Suggests:       hyprsunset
Suggests:       power-profiles-daemon
Suggests:       swww

%description
faiyt-qs is a feature-rich desktop shell for Hyprland built with QuickShell
(Qt6 QML). It provides a top bar, dual sidebars, launcher, settings panel,
overview mode, and notification system with the Rosé Pine color theme.

Features include:
- Top bar with workspaces, system tray, media controls, and more
- AI-powered chat with Claude integration
- Application launcher with instant evaluators
- Screen capture and recording
- Theme customization with live preview
- Monitor configuration
- Notification system

%prep
%autosetup -n faiyt-quickshell-%{version}

%build
# Nothing to build - pure QML

%install
# Install to /usr/share/faiyt-qs
install -dm755 %{buildroot}%{_datadir}/%{name}
cp -r shell.qml theme components services scripts %{buildroot}%{_datadir}/%{name}/

# Make scripts executable
chmod +x %{buildroot}%{_datadir}/%{name}/scripts/*.sh
chmod +x %{buildroot}%{_datadir}/%{name}/scripts/*.py 2>/dev/null || true

# Install documentation
install -Dm644 README.md %{buildroot}%{_docdir}/%{name}/README.md
install -Dm644 CLAUDE.md %{buildroot}%{_docdir}/%{name}/CLAUDE.md

# Create quickshell config symlink location
install -dm755 %{buildroot}%{_datadir}/quickshell
ln -sf %{_datadir}/%{name} %{buildroot}%{_datadir}/quickshell/%{name}

# Install wrapper script
install -Dm755 /dev/stdin %{buildroot}%{_bindir}/%{name} << 'EOF'
#!/bin/bash
# faiyt-qs launcher wrapper
exec quickshell -p %{_datadir}/faiyt-qs/shell.qml "$@"
EOF

# Install desktop entry
install -dm755 %{buildroot}%{_datadir}/wayland-sessions
cat > %{buildroot}%{_datadir}/wayland-sessions/%{name}.desktop << EOF
[Desktop Entry]
Name=faiyt-qs (Hyprland)
Comment=QuickShell desktop shell for Hyprland
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF

%files
%license LICENSE
%doc README.md CLAUDE.md
%{_bindir}/%{name}
%{_datadir}/%{name}/
%{_datadir}/quickshell/%{name}
%{_datadir}/wayland-sessions/%{name}.desktop

%changelog
* Mon Jan 06 2025 Your Name <your.email@example.com> - 1.0.0-1
- Initial package release
