#!/bin/bash
# IB GNOME RICE V13 — Script 03: Dock geometry, glass, and no bad gsettings keys
# Fixes v12 errors: no leftBox-padding/rightBox-padding crash, and avoids styling the wrong empty center box.
set -euo pipefail

DTP='org.gnome.shell.extensions.dash-to-panel'
DTP_CSS='/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/stylesheet.css'

key_exists() { gsettings list-keys "$1" 2>/dev/null | grep -qx "$2"; }
setg() { local schema="$1" key="$2" value="$3"; key_exists "$schema" "$key" && gsettings set "$schema" "$key" "$value" || true; }
setstr() { local schema="$1" key="$2" value="$3"; key_exists "$schema" "$key" && gsettings set "$schema" "$key" "'$value'" || true; }

MK="$(gsettings get "$DTP" panel-lengths 2>/dev/null | sed "s/^'//; s/'$//" | python3 -c "import sys,json; d=json.load(sys.stdin); print(list(d.keys())[0])" 2>/dev/null || echo '0')"
[ -n "$MK" ] || MK='0'

setg "$DTP" panel-position "'BOTTOM'"
setstr "$DTP" panel-positions "{\"$MK\":\"BOTTOM\"}"
setstr "$DTP" panel-anchors "{\"$MK\":\"MIDDLE\"}"

# Deliberate v13 choice: 74% centred panel instead of v12's 0 dynamic mode.
# On your current setup, 0 did not produce the visual dock you wanted.
setstr "$DTP" panel-lengths "{\"$MK\":74}"
setstr "$DTP" panel-sizes "{\"$MK\":54}"
setg "$DTP" panel-size 54

setg "$DTP" stockgs-keep-top-panel false
setg "$DTP" show-activities-button false
setg "$DTP" show-favorites true
setg "$DTP" show-running-apps true
setg "$DTP" group-apps true
setg "$DTP" isolate-workspaces false

setg "$DTP" trans-use-custom-bg true
setstr "$DTP" trans-bg-color '#0a0d14'
setg "$DTP" trans-use-custom-opacity true
setg "$DTP" trans-panel-opacity 0.58
setg "$DTP" trans-use-dynamic-opacity false
setg "$DTP" trans-use-custom-gradient false

setg "$DTP" global-border-radius 28
setg "$DTP" appicon-padding 4
setg "$DTP" appicon-margin 2
setg "$DTP" tray-padding 2
setg "$DTP" status-icon-padding 2
setg "$DTP" dot-style-focused "'DOTS'"
setg "$DTP" dot-style-unfocused "'DOTS'"
setg "$DTP" dot-position "'BOTTOM'"
setg "$DTP" dot-size 3
setg "$DTP" dot-color-dominant true
setg "$DTP" dot-color-override false
setg "$DTP" animate-appicon-hover false
setg "$DTP" highlight-appicon-hover true
setstr "$DTP" highlight-appicon-hover-background-color 'rgba(255,255,255,0.10)'
setg "$DTP" intellihide true
setg "$DTP" intellihide-close-delay 600
setg "$DTP" intellihide-animation-time 140
setg "$DTP" intellihide-use-pressure false
setg "$DTP" intellihide-reveal-delay 0
setg "$DTP" intellihide-mode "'ALL_WINDOWS'"
setg "$DTP" intellihide-behaviour "'FOCUSED_WINDOWS'"
setg "$DTP" panel-top-bottom-margins 10
setg "$DTP" panel-side-margins 0
setg "$DTP" panel-top-bottom-padding 0
setg "$DTP" panel-side-padding 10

setstr "$DTP" panel-element-positions "{\"$MK\":[{\"element\":\"showAppsButton\",\"visible\":false,\"position\":\"stackedTL\"},{\"element\":\"activitiesButton\",\"visible\":false,\"position\":\"stackedTL\"},{\"element\":\"leftBox\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"taskbar\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"centerBox\",\"visible\":false,\"position\":\"centerMonitor\"},{\"element\":\"dateMenu\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"rightBox\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"systemMenu\",\"visible\":true,\"position\":\"stackedBR\"}]}"

gsettings set org.gnome.shell favorite-apps "['ib-arch-menu.desktop','firefox.desktop','org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop','code.desktop']"

if [ -f "$DTP_CSS" ]; then
    sudo cp "$DTP_CSS" "$DTP_CSS.bak.v13.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
    sudo sed -i '/IB_V13_DOCK_BEGIN/,/IB_V13_DOCK_END/d' "$DTP_CSS"
    sudo sed -i '/IB_V12_BEGIN/,/IB_V12_END/d' "$DTP_CSS"
    sudo sed -i '/IB_V11_BEGIN/,/IB_V11_END/d' "$DTP_CSS"
    sudo tee -a "$DTP_CSS" >/dev/null <<'CSS'
/* IB_V13_DOCK_BEGIN */

#panelBox,
#panelBox > StBoxLayout,
#panelBox .panel,
#panelBox .panel-corner,
#panel .panel-corner {
    background: transparent !important;
    background-color: transparent !important;
    box-shadow: none !important;
    border: none !important;
}

#panel,
#panel.dashtopanelMainPanel,
.dashtopanelMainPanel {
    background-color: rgba(10, 13, 20, 0.60) !important;
    border: 1px solid rgba(255, 255, 255, 0.14) !important;
    border-radius: 28px !important;
    box-shadow:
        0 10px 34px rgba(0, 0, 0, 0.45),
        0 3px 12px rgba(0, 0, 0, 0.30),
        inset 0 1px 0 rgba(255, 255, 255, 0.10),
        inset 0 -1px 0 rgba(255, 255, 255, 0.04) !important;
    margin-bottom: 10px !important;
    padding: 0 10px !important;
}

#panelLeft,
#panelCenter,
#panelRight,
#panel .dashtopanel-box,
#panel .dashtopanel-box-center,
#panel .dashtopanel-box-left,
#panel .dashtopanel-box-right {
    background: transparent !important;
    background-color: transparent !important;
    box-shadow: none !important;
    border: none !important;
}

#panel .panel-button,
#panel .app-well-app .overview-icon,
#panel .show-apps .overview-icon {
    border-radius: 16px !important;
    transition: none !important;
}

#panel .panel-button:hover,
#panel .app-well-app:hover .overview-icon,
#panel .show-apps:hover .overview-icon {
    background-color: rgba(255, 255, 255, 0.09) !important;
    border-radius: 16px !important;
}

#panel .panel-button.clock-display,
#panel .clock-display {
    background-color: rgba(255, 255, 255, 0.08) !important;
    border: 1px solid rgba(255, 255, 255, 0.11) !important;
    border-radius: 20px !important;
    padding: 4px 12px !important;
    margin: 6px 3px !important;
    box-shadow: none !important;
    font-size: 13px !important;
}

#panel .dashtopanel-separator,
#panel .dash-separator {
    background: rgba(255, 255, 255, 0.10) !important;
    width: 1px !important;
    margin: 10px 6px !important;
}

/* IB_V13_DOCK_END */
CSS
fi

gnome-extensions disable dash-to-panel@jderose9.github.com 2>/dev/null || true
sleep 1
gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true

echo '03 ✓ Dock v13 applied: centred 74% glass pill, safe gsettings, no invalid leftBox/tile keys.'
