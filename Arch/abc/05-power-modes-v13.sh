#!/bin/bash
# IB GNOME RICE V13 — Script 05: Five-mode power system + GNOME Quick Settings entry
# Adds Turbo, Performance, Normal, PowerSaving, Ultra-PowerSaving to Super+A.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
CFG_DIR="$HOME/.config/ib-rice"
EXT_BASE="$HOME/.local/share/gnome-shell/extensions"
EXT_UUID='ib-power-modes@ibLaptop'
EXT_DIR="$EXT_BASE/$EXT_UUID"
mkdir -p "$BIN_DIR" "$CFG_DIR" "$EXT_DIR" "$HOME/.config/autostart"

sudo pacman -S --needed --noconfirm power-profiles-daemon brightnessctl zenity >/dev/null 2>&1 || true
sudo systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1 || true

cat > "$BIN_DIR/ib-power-mode" <<'EOS'
#!/bin/bash
set -euo pipefail

CFG_DIR="$HOME/.config/ib-rice"
MODE_FILE="$CFG_DIR/power-mode"
WALL_FILE="$CFG_DIR/wallpaper-enabled"
mkdir -p "$CFG_DIR"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send --icon=preferences-system-power-symbolic "Power Mode" "$1" || true; }
read_mode() { [ -f "$MODE_FILE" ] && cat "$MODE_FILE" || echo normal; }
safe_gset() { local schema="$1" key="$2" value="$3"; if gsettings list-keys "$schema" 2>/dev/null | grep -qx "$key"; then gsettings set "$schema" "$key" "$value" >/dev/null 2>&1 || true; fi; }

set_ppd() {
    local target="$1"
    if ! command -v powerprofilesctl >/dev/null 2>&1; then return 0; fi
    if powerprofilesctl list 2>/dev/null | grep -q "^[*[:space:]]*$target:"; then
        powerprofilesctl set "$target" >/dev/null 2>&1 || true
    fi
}

try_governor() {
    local governor="$1"
    if command -v cpupower >/dev/null 2>&1; then
        sudo -n cpupower frequency-set -g "$governor" >/dev/null 2>&1 || true
    fi
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -w "$f" ] && echo "$governor" > "$f" 2>/dev/null || sudo -n sh -c "echo '$governor' > '$f'" >/dev/null 2>&1 || true
    done
}

try_perf_pct() {
    local min="$1" max="$2"
    [ -e /sys/devices/system/cpu/intel_pstate/min_perf_pct ] && sudo -n sh -c "echo '$min' > /sys/devices/system/cpu/intel_pstate/min_perf_pct" >/dev/null 2>&1 || true
    [ -e /sys/devices/system/cpu/intel_pstate/max_perf_pct ] && sudo -n sh -c "echo '$max' > /sys/devices/system/cpu/intel_pstate/max_perf_pct" >/dev/null 2>&1 || true
}

set_brightness() {
    local val="$1"
    command -v brightnessctl >/dev/null 2>&1 || return 0
    brightnessctl set "$val" >/dev/null 2>&1 || true
}

set_fast_ui() {
    safe_gset org.gnome.desktop.interface enable-animations false
    safe_gset org.gnome.shell.extensions.dash-to-panel intellihide-animation-time 1
    safe_gset org.gnome.shell.extensions.dash-to-panel intellihide-close-delay 0
    safe_gset org.gnome.shell.extensions.dash-to-panel intellihide-reveal-delay 0
    safe_gset org.gnome.shell.extensions.dash-to-panel animate-appicon-hover false
}

set_pretty_ui() {
    safe_gset org.gnome.desktop.interface enable-animations true
    safe_gset org.gnome.shell.extensions.dash-to-panel intellihide-animation-time 180
    safe_gset org.gnome.shell.extensions.dash-to-panel intellihide-close-delay 650
    safe_gset org.gnome.shell.extensions.dash-to-panel intellihide-reveal-delay 0
    safe_gset org.gnome.shell.extensions.dash-to-panel animate-appicon-hover false
}

apply_mode() {
    local mode="${1,,}"
    case "$mode" in
        turbo)
            echo turbo > "$MODE_FILE"
            echo 1 > "$WALL_FILE"
            set_ppd performance
            set_fast_ui
            try_governor performance
            try_perf_pct 100 100
            notify 'Turbo: maximum performance, fastest UI, no power saving.'
            ;;
        performance)
            echo performance > "$MODE_FILE"
            echo 1 > "$WALL_FILE"
            set_ppd performance
            set_fast_ui
            try_governor performance
            try_perf_pct 10 100
            notify 'Performance: high performance, fast UI, idle throttling allowed.'
            ;;
        normal|balanced)
            echo normal > "$MODE_FILE"
            echo 1 > "$WALL_FILE"
            set_ppd balanced
            set_pretty_ui
            try_governor schedutil
            try_perf_pct 0 100
            notify 'Normal: balanced profile, normal animations, wallpaper rotation enabled.'
            ;;
        powersaving|power-saving|power_saving)
            echo powersaving > "$MODE_FILE"
            echo 0 > "$WALL_FILE"
            set_ppd power-saver
            set_pretty_ui
            try_governor powersave
            try_perf_pct 0 65
            set_brightness 35%
            notify 'PowerSaving: power-saver profile, wallpaper rotation disabled.'
            ;;
        ultra|ultra-powersaving|ultra_power_saving|ultrapowersaving)
            echo ultra-powersaving > "$MODE_FILE"
            echo 0 > "$WALL_FILE"
            set_ppd power-saver
            set_pretty_ui
            try_governor powersave
            try_perf_pct 0 45
            set_brightness 5%
            notify 'Ultra-PowerSaving: lowest brightness and strongest battery-saving profile.'
            ;;
        *)
            echo "Unknown mode: $mode" >&2
            exit 2
            ;;
    esac
}

menu() {
    local battery_present=0
    compgen -G '/sys/class/power_supply/BAT*' >/dev/null && battery_present=1
    local options=$'Turbo — maximum CPU/GPU/fans, fastest UI\nPerformance — high performance, fast UI\nNormal — boot/default balanced mode\nPowerSaving — saver mode, wallpaper rotation off'
    [ "$battery_present" -eq 1 ] && options+=$'\nUltra-PowerSaving — laptop battery survival mode'
    local choice=''
    if command -v wofi >/dev/null 2>&1; then
        choice="$(printf '%s\n' "$options" | wofi --dmenu --prompt 'Power Mode' --width 620 --height 330 --insensitive)"
    elif command -v rofi >/dev/null 2>&1; then
        choice="$(printf '%s\n' "$options" | rofi -dmenu -p 'Power Mode')"
    elif command -v zenity >/dev/null 2>&1; then
        choice="$(printf '%s\n' "$options" | zenity --list --title='Power Mode' --column='Mode')"
    else
        printf '%s\n' "$options"
        exit 0
    fi
    case "$choice" in
        Turbo*) apply_mode turbo ;;
        Performance*) apply_mode performance ;;
        Normal*) apply_mode normal ;;
        PowerSaving*) apply_mode powersaving ;;
        Ultra*) apply_mode ultra-powersaving ;;
        *) exit 0 ;;
    esac
}

case "${1:-menu}" in
    set) apply_mode "${2:-normal}" ;;
    get) read_mode ;;
    menu|gui) menu ;;
    *) echo "Usage: ib-power-mode set MODE|get|menu" >&2; exit 2 ;;
esac
EOS
chmod +x "$BIN_DIR/ib-power-mode"
sudo ln -sf "$BIN_DIR/ib-power-mode" /usr/local/bin/ib-power-mode 2>/dev/null || true

# Patch wallpaper cycling so PowerSaving/Ultra really disables extra wallpaper work.
if [ -x "$BIN_DIR/ib-next-background" ]; then
    cp "$BIN_DIR/ib-next-background" "$BIN_DIR/ib-next-background.bak.v13.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
fi
cat > "$BIN_DIR/ib-next-background" <<'EOS'
#!/bin/bash
set -euo pipefail
CFG="$HOME/.config/ib-rice/wallpaper-enabled"
if [ -f "$CFG" ] && [ "$(cat "$CFG")" = "0" ]; then
    notify-send --icon=preferences-desktop-wallpaper 'Wallpaper' 'Wallpaper rotation is disabled in the current power-saving mode.' 2>/dev/null || true
    exit 0
fi
WALL_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="$HOME/.cache/ib-wallpaper-index"
mkdir -p "$(dirname "$STATE_FILE")"
[ -d "$WALL_DIR" ] || exit 0
mapfile -t WALLS < <(find "$WALL_DIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
[ "${#WALLS[@]}" -gt 0 ] || exit 0
IDX=0
[ -f "$STATE_FILE" ] && IDX="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"
IDX=$(( (IDX + 1) % ${#WALLS[@]} ))
printf '%s' "$IDX" > "$STATE_FILE"
RAW="${WALLS[$IDX]}"
FINAL="$RAW"
command -v ib-wallpaper-prep >/dev/null 2>&1 && FINAL="$(ib-wallpaper-prep "$RAW" 2>/dev/null || echo "$RAW")"
URI="file://$FINAL"
gsettings set org.gnome.desktop.background picture-uri "$URI"
gsettings set org.gnome.desktop.background picture-uri-dark "$URI"
gsettings set org.gnome.desktop.screensaver picture-uri "$URI"
notify-send --icon=preferences-desktop-wallpaper 'Wallpaper' "$(basename "$RAW")" 2>/dev/null || true
EOS
chmod +x "$BIN_DIR/ib-next-background"

cat > "$EXT_DIR/metadata.json" <<'JSON'
{
  "uuid": "ib-power-modes@ibLaptop",
  "name": "IB Power Modes v13",
  "description": "Adds Turbo, Performance, Normal, PowerSaving and Ultra-PowerSaving to GNOME Quick Settings.",
  "shell-version": ["45","46","47","48","49","50"],
  "session-modes": ["user"]
}
JSON

cat > "$EXT_DIR/extension.js" <<'JS'
import GObject from 'gi://GObject';
import GLib from 'gi://GLib';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as QuickSettings from 'resource:///org/gnome/shell/ui/quickSettings.js';

const HOME = GLib.get_home_dir();
const MODE_FILE = `${HOME}/.config/ib-rice/power-mode`;
const CMD = `${HOME}/.local/bin/ib-power-mode`;

function readMode() {
    try {
        const [, bytes] = GLib.file_get_contents(MODE_FILE);
        return new TextDecoder().decode(bytes).trim();
    } catch {
        return 'normal';
    }
}

function label(mode) {
    switch ((mode ?? '').toLowerCase()) {
        case 'turbo': return 'Turbo';
        case 'performance': return 'Performance';
        case 'powersaving': return 'PowerSaving';
        case 'ultra-powersaving': return 'Ultra-PowerSaving';
        default: return 'Normal';
    }
}

const PowerToggle = GObject.registerClass(
class PowerToggle extends QuickSettings.QuickMenuToggle {
    _init() {
        super._init({
            title: 'Power Mode',
            subtitle: label(readMode()),
            iconName: 'preferences-system-power-symbolic',
            toggleMode: false,
        });

        this.menu.setHeader('preferences-system-power-symbolic', 'IB Power Modes', label(readMode()));
        this._section = new PopupMenu.PopupMenuSection();

        this._addMode('Turbo', 'turbo');
        this._addMode('Performance', 'performance');
        this._addMode('Normal', 'normal');
        this._addMode('PowerSaving', 'powersaving');
        this._addMode('Ultra-PowerSaving', 'ultra-powersaving');

        this.menu.addMenuItem(this._section);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this.menu.addAction('Open Power Mode Selector', () => GLib.spawn_command_line_async(`${CMD} menu`));

        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
        this._refresh();
    }

    _addMode(title, mode) {
        this._section.addAction(title, () => {
            GLib.spawn_command_line_async(`${CMD} set ${mode}`);
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 220, () => {
                this._refresh();
                return GLib.SOURCE_REMOVE;
            });
        });
    }

    _refresh() {
        const mode = label(readMode());
        this.subtitle = mode;
        try { this.menu.setHeader('preferences-system-power-symbolic', 'IB Power Modes', mode); } catch {}
    }

    destroy() {
        if (this._timer) GLib.source_remove(this._timer);
        super.destroy();
    }
});

const PowerIndicator = GObject.registerClass(
class PowerIndicator extends QuickSettings.SystemIndicator {
    _init() {
        super._init();
        this.quickSettingsItems.push(new PowerToggle());
    }
    destroy() {
        this.quickSettingsItems.forEach(item => item.destroy());
        super.destroy();
    }
});

export default class IbPowerModesExtension extends Extension {
    enable() {
        this._indicator = new PowerIndicator();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator, 1);
    }
    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
JS

python3 - <<'PY'
import ast, subprocess
schema='org.gnome.shell'; key='enabled-extensions'; ext='ib-power-modes@ibLaptop'
raw=subprocess.check_output(['gsettings','get',schema,key], text=True).strip()
try: vals=ast.literal_eval(raw)
except Exception: vals=[]
if ext not in vals: vals.append(ext)
subprocess.run(['gsettings','set',schema,key,str(vals).replace('"',"'")], check=True)
PY

gnome-extensions enable "$EXT_UUID" 2>/dev/null || true

cat > "$HOME/.config/autostart/ib-power-mode-normal.desktop" <<EOF2
[Desktop Entry]
Type=Application
Name=IB Power Mode Default
Exec=$BIN_DIR/ib-power-mode set normal
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF2

# Set current state to Normal now, as requested boot/default behaviour.
"$BIN_DIR/ib-power-mode" set normal >/dev/null 2>&1 || true

echo '05 ✓ Power modes v13 installed: Quick Settings menu + Super+P + Normal default + wallpaper disable in saving modes.'
