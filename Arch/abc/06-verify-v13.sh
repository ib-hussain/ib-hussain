#!/bin/bash
# IB GNOME RICE V13 — Verify/status report
set -euo pipefail

OUT="$HOME/rice-v13-status.txt"
PASS=0; WARN=0; FAIL=0
rm -f "$OUT"

pass(){ echo "  ✓ PASS: $1" | tee -a "$OUT"; PASS=$((PASS+1)); }
warn(){ echo "  ⚠ WARN: $1" | tee -a "$OUT"; WARN=$((WARN+1)); }
fail(){ echo "  ✗ FAIL: $1" | tee -a "$OUT"; FAIL=$((FAIL+1)); }
info(){ echo "       $1" | tee -a "$OUT"; }
section(){ echo; echo "── $1 ──" | tee -a "$OUT"; }
get(){ gsettings get "$1" "$2" 2>/dev/null || echo unavailable; }

HOST="$(cat /etc/hostname 2>/dev/null || uname -n 2>/dev/null || echo unknown)"
{
    echo '╔══════════════════════════════════════════════════════╗'
    echo '║        IB GNOME RICE V13 — STATUS REPORT             ║'
    echo '╚══════════════════════════════════════════════════════╝'
    echo "Generated: $(date)"
    echo "Hostname:  $HOST"
} | tee "$OUT"

section 'Session'
info "Type:    ${XDG_SESSION_TYPE:-unknown}"
info "Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
[ "${XDG_SESSION_TYPE:-}" = wayland ] && pass 'GNOME Wayland session active' || warn "Session is not Wayland: ${XDG_SESSION_TYPE:-none}"

section 'Extensions'
ENABLED="$(gnome-extensions list --enabled 2>/dev/null || echo '')"
for ext in \
    'dash-to-panel@jderose9.github.com:Dash-to-Panel' \
    'ib-desktop-clock@ibLaptop:Desktop Clock v13' \
    'ib-window-opacity@ibLaptop:Immediate Window Opacity v13' \
    'ib-power-modes@ibLaptop:Power Modes Quick Settings v13' \
    'appindicatorsupport@rgcjonas.gmail.com:App Indicators' \
    'ding@rastersoft.com:Desktop Icons NG'
do
    uuid="${ext%%:*}"; name="${ext##*:}"
    printf '%s\n' "$ENABLED" | grep -qx "$uuid" && pass "$name enabled" || warn "$name not enabled ($uuid)"
done

section 'Clock'
CLOCK="$HOME/.local/share/gnome-shell/extensions/ib-desktop-clock@ibLaptop"
[ -f "$CLOCK/extension.js" ] && pass 'Clock extension.js present' || fail 'Clock extension.js missing'
grep -q 'duration: 650' "$CLOCK/extension.js" 2>/dev/null && pass 'Clock fade-in set to 650ms' || warn 'Clock fade-in not confirmed'
grep -q 'm.y + 18' "$CLOCK/extension.js" 2>/dev/null && pass 'Clock top position set to 18px' || warn 'Clock top position not confirmed'
grep -q 'font-size: 58px' "$CLOCK/stylesheet.css" 2>/dev/null && pass 'Clock time font set to 58px' || warn 'Clock font not confirmed'

section 'Window Opacity'
OP="$HOME/.local/share/gnome-shell/extensions/ib-window-opacity@ibLaptop/extension.js"
grep -q 'actor.opacity = isSystemApp' "$OP" 2>/dev/null && pass 'Window opacity applied instantly' || warn 'Opacity instant assignment not confirmed'
if grep -q '_smoothOpacity' "$OP" 2>/dev/null; then warn 'Old smooth opacity function still present'; else pass 'Old smooth opacity transition removed'; fi

section 'Dock'
DTP='org.gnome.shell.extensions.dash-to-panel'
info "Position: $(get "$DTP" panel-position)"
info "Lengths:  $(get "$DTP" panel-lengths)"
info "Opacity:  $(get "$DTP" trans-panel-opacity)"
info "Radius:   $(get "$DTP" global-border-radius)"
grep -q 'IB_V13_DOCK_BEGIN' /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/stylesheet.css 2>/dev/null && pass 'V13 dock CSS patch present' || warn 'V13 dock CSS patch missing'

section 'Start Menu / Keybindings'
[ -x "$HOME/.local/bin/ib-start-menu" ] && pass 'ib-start-menu executable' || fail 'ib-start-menu missing'
[ -x "$HOME/.local/bin/ib-app-search" ] && pass 'ib-app-search executable' || fail 'ib-app-search missing'
[ -x "$HOME/.local/bin/ib-power-mode" ] && pass 'ib-power-mode executable' || fail 'ib-power-mode missing'
info "overlay-key: $(get org.gnome.mutter overlay-key)"
info "Super+D: $(get org.gnome.desktop.wm.keybindings show-desktop)"
info "Super+S: $(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/' binding 2>/dev/null || echo unavailable)"
info "Super+P: $(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/' binding 2>/dev/null || echo unavailable)"
info "Ctrl+Shift+Esc: $(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/' binding 2>/dev/null || echo unavailable)"

section 'Power Modes'
MODE="$(cat "$HOME/.config/ib-rice/power-mode" 2>/dev/null || echo unknown)"
WALL="$(cat "$HOME/.config/ib-rice/wallpaper-enabled" 2>/dev/null || echo unknown)"
info "IB mode: $MODE"
info "Wallpaper enabled: $WALL"
if command -v powerprofilesctl >/dev/null 2>&1; then
    info "Native profile: $(powerprofilesctl get 2>/dev/null || echo unavailable)"
    pass 'powerprofilesctl available'
else
    warn 'powerprofilesctl missing'
fi

section 'Known reality checks'
warn 'GNOME Settings itself cannot be extended like a normal app by only dropping a user script; v13 adds Power Modes to Quick Settings and as a Settings-category app instead.'
warn 'Turbo CPU governor forcing needs kernel cpufreq support and passwordless/root permission; inside VirtualBox it may be skipped silently.'
warn 'On Wayland, Shell extension changes require logout/login to reload cleanly.'

echo
printf '  Results: %d PASS / %d WARN / %d FAIL\n' "$PASS" "$WARN" "$FAIL" | tee -a "$OUT"
echo "Report saved: $OUT" | tee -a "$OUT"
