#!/bin/bash
# IB GNOME RICE V13 — Script 04: Super key and Arch icon behaviour split
# Super / Arch icon -> Start menu. Super+S -> app search. No bad tile-left crash.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
mkdir -p "$BIN_DIR" "$APP_DIR" "$HOME/.config/wofi" "$HOME/.config/rofi"

ICON_PNG="$HOME/.cache/ib-arch-wallpaper-repo/Arch/arch-logo.png"
ICON_WEBP="$HOME/.cache/ib-arch-wallpaper-repo/Arch/arch-logo.webp"
ICON="$ICON_PNG"
[ -f "$ICON" ] || ICON="$ICON_WEBP"
[ -f "$ICON" ] || ICON='archlinux-logo'

cat > "$BIN_DIR/ib-start-menu" <<'EOS'
#!/bin/bash
set -euo pipefail

choose() {
    local prompt="$1"
    if command -v wofi >/dev/null 2>&1; then
        wofi --dmenu --prompt "$prompt" --width 520 --height 430 --insensitive --allow-images
    elif command -v rofi >/dev/null 2>&1; then
        rofi -dmenu -p "$prompt"
    else
        cat >/tmp/ib-menu-options.txt
        sed -n '1p' /tmp/ib-menu-options.txt
    fi
}

MENU=$'Apps Search\nFiles\nTerminal\nVisual Studio Code\nSettings\nPower Modes\nTask Manager\nNext Wallpaper\nLock\nLog Out\nRestart\nShut Down'
CHOICE="$(printf '%s\n' "$MENU" | choose 'Arch Menu')"
case "$CHOICE" in
    'Apps Search') exec "$HOME/.local/bin/ib-app-search" ;;
    'Files') exec gtk-launch org.gnome.Nautilus.desktop ;;
    'Terminal') exec gtk-launch org.gnome.Terminal.desktop ;;
    'Visual Studio Code') exec gtk-launch code.desktop ;;
    'Settings') exec gtk-launch org.gnome.Settings.desktop ;;
    'Power Modes') exec "$HOME/.local/bin/ib-power-mode" menu ;;
    'Task Manager') exec "$HOME/.local/bin/ib-htop-fullscreen" ;;
    'Next Wallpaper') exec "$HOME/.local/bin/ib-next-background" ;;
    'Lock') exec loginctl lock-session ;;
    'Log Out') gnome-session-quit --logout --no-prompt ;;
    'Restart') systemctl reboot ;;
    'Shut Down') systemctl poweroff ;;
    *) exit 0 ;;
esac
EOS
chmod +x "$BIN_DIR/ib-start-menu"

cat > "$APP_DIR/ib-arch-menu.desktop" <<EOF2
[Desktop Entry]
Type=Application
Name=Arch Menu
Comment=Open IB start menu
Exec=$BIN_DIR/ib-start-menu
Icon=$ICON
Terminal=false
Categories=System;Utility;
StartupNotify=false
EOF2

cat > "$APP_DIR/ib-power-modes.desktop" <<EOF2
[Desktop Entry]
Type=Application
Name=IB Power Modes
Comment=Switch Turbo, Performance, Normal, PowerSaving, and Ultra-PowerSaving modes
Exec=$BIN_DIR/ib-power-mode menu
Icon=preferences-system-power-symbolic
Terminal=false
Categories=Settings;System;Utility;
Keywords=power;battery;performance;turbo;saving;
StartupNotify=false
EOF2

# Keep Super+S as direct search launcher.
cat > "$BIN_DIR/ib-app-search" <<'EOS'
#!/bin/bash
set -euo pipefail
if command -v wofi >/dev/null 2>&1; then
    exec wofi --show drun --allow-images --width 680 --height 520 --insensitive --prompt '  Search…'
fi
if command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun
fi
exec gtk-launch org.gnome.Nautilus.desktop
EOS
chmod +x "$BIN_DIR/ib-app-search"

safe_set() { local schema="$1" key="$2" value="$3"; if gsettings list-keys "$schema" 2>/dev/null | grep -qx "$key"; then gsettings set "$schema" "$key" "$value" || true; fi; }
ckb_base='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings'

safe_set org.gnome.mutter overlay-key "''"
safe_set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
safe_set org.gnome.desktop.wm.keybindings close "['<Alt>F4']"
safe_set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
safe_set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
safe_set org.gnome.desktop.wm.keybindings tile-left "['<Super>Left']"
safe_set org.gnome.desktop.wm.keybindings tile-right "['<Super>Right']"
safe_set org.gnome.desktop.wm.keybindings tile-to-left "['<Super>Left']"
safe_set org.gnome.desktop.wm.keybindings tile-to-right "['<Super>Right']"
safe_set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
safe_set org.gnome.desktop.wm.keybindings switch-windows "['<Super>Tab']"
safe_set org.gnome.shell.keybindings show-screenshot-ui "['<Super><Shift>s']"
safe_set org.gnome.shell.keybindings toggle-quick-settings "['<Super>a']"
safe_set org.gnome.shell.keybindings toggle-application-view "[]"
safe_set org.gnome.shell.keybindings toggle-overview "[]"

for i in $(seq 0 9); do
    gsettings reset-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$ckb_base/custom${i}/" 2>/dev/null || true
done

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$ckb_base/custom0/','$ckb_base/custom1/','$ckb_base/custom2/','$ckb_base/custom3/','$ckb_base/custom4/','$ckb_base/custom5/','$ckb_base/custom6/','$ckb_base/custom7/']"

set_ckb() {
    local slot="$1" name="$2" cmd="$3" bind="$4"
    local path="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$ckb_base/custom${slot}/"
    gsettings set "$path" name "$name"
    gsettings set "$path" command "$cmd"
    gsettings set "$path" binding "$bind"
}

set_ckb 0 'IB Start Menu (tap Super)' "$BIN_DIR/ib-start-menu" '<F13>'
set_ckb 1 'IB App Search' "$BIN_DIR/ib-app-search" '<Super>s'
set_ckb 2 'Files' 'gtk-launch org.gnome.Nautilus.desktop' '<Super>e'
set_ckb 3 'Terminal' 'gtk-launch org.gnome.Terminal.desktop' '<Primary><Alt>t'
set_ckb 4 'Power Modes' "$BIN_DIR/ib-power-mode menu" '<Super>p'
set_ckb 5 'Task Manager' "$BIN_DIR/ib-htop-fullscreen" '<Primary><Shift>Escape'
set_ckb 6 'Next Background' "$BIN_DIR/ib-next-background" '<Super>n'
set_ckb 7 'Lock Screen' 'loginctl lock-session' '<Super>l'

if command -v keyd >/dev/null 2>&1; then
    sudo mkdir -p /etc/keyd
    sudo tee /etc/keyd/default.conf >/dev/null <<'KEYD'
[ids]
*

[main]
leftmeta = overload(meta, f13)
rightmeta = overload(meta, f13)
KEYD
    sudo modprobe uinput 2>/dev/null || true
    echo uinput | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
    sudo systemctl enable --now keyd.service 2>/dev/null || true
    sudo keyd reload 2>/dev/null || sudo systemctl restart keyd.service 2>/dev/null || true
fi

gsettings set org.gnome.shell favorite-apps "['ib-arch-menu.desktop','firefox.desktop','org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop','code.desktop']"

echo '04 ✓ Start/menu fixed: bare Super and Arch icon open Start Menu; Super+S remains app search.'
