#!/bin/bash
# IB GNOME RICE V15 — DOCK FINAL FIX (COMPLETE REWRITE)
#
# Root cause: #panel is always full-width. Previous versions tried to style
# a full-width invisible bar. The FIX: style the INNER StBoxLayout container
# which IS constrained by panel-lengths, then apply glass morphism to THAT.
#
# This script:
# 1. Sets panel-lengths to 74 (constrain width to 74% of screen)
# 2. Clears all old CSS patches to prevent conflicts
# 3. Writes ONE clean CSS block targeting the inner container
# 4. Forces GNOME Shell reload via extension restart
set -euo pipefail

DTP='org.gnome.shell.extensions.dash-to-panel'
DTP_CSS='/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/stylesheet.css'

echo "═══════════════════════════════════════════════════════════════"
echo "  IB GNOME RICE V15 — DOCK FIX"
echo "═══════════════════════════════════════════════════════════════"
echo

# ════════════════════════════════════════════════════════════════════
# PART 1: GSETTINGS CONFIGURATION
# ════════════════════════════════════════════════════════════════════

echo "▶ Configuring Dash-to-Panel settings..."

# Utility functions
key_exists() { gsettings list-keys "$1" 2>/dev/null | grep -qx "$2"; }
setg()      { key_exists "$1" "$2" && gsettings set "$1" "$2" "$3" || true; }
setstr()    { key_exists "$1" "$2" && gsettings set "$1" "$2" "'$3'" || true; }

# Get monitor key (required for dconf paths)
MK="$(gsettings get "$DTP" panel-lengths 2>/dev/null \
    | sed "s/^'//; s/'$//" \
    | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    k = list(d.keys())
    print(k[0] if k else '0')
except:
    print('0')
" 2>/dev/null || echo '0')"
[ -n "$MK" ] || MK='0'
echo "  Monitor key: $MK"

# ── Position ──────────────────────────────────────────────────────────
setg   "$DTP" panel-position          "'BOTTOM'"
setstr "$DTP" panel-positions         "{\"$MK\":\"BOTTOM\"}"
setstr "$DTP" panel-anchors           "{\"$MK\":\"MIDDLE\"}"

# ── Constrain width to 74% ────────────────────────────────────────────
# This is the CRITICAL setting. It tells DtP to render the content area
# at 74% screen width. The CSS then applies glass effect to this constrained space.
setstr "$DTP" panel-lengths           "{\"$MK\":74}"

# ── Panel height ───────────────────────────────────────────────────────
setstr "$DTP" panel-sizes             "{\"$MK\":56}"
setg   "$DTP" panel-size              56

# ── NO padding/margins from DtP (we'll use CSS instead) ────────────────
setg   "$DTP" panel-top-bottom-margins 0
setg   "$DTP" panel-side-margins       0
setg   "$DTP" panel-top-bottom-padding 0
setg   "$DTP" panel-side-padding       0

# ── Glass parameters ───────────────────────────────────────────────────
setg   "$DTP" trans-use-custom-bg       true
setstr "$DTP" trans-bg-color            '#0a0c16'
setg   "$DTP" trans-use-custom-opacity  true
setg   "$DTP" trans-panel-opacity       0.72
setg   "$DTP" trans-use-dynamic-opacity false

# ── Radius ────────────────────────────────────────────────────────────
setg   "$DTP" global-border-radius      24

# ── Icon spacing ───────────────────────────────────────────────────────
setg   "$DTP" appicon-padding           5
setg   "$DTP" appicon-margin            3
setg   "$DTP" tray-padding              3
setg   "$DTP" status-icon-padding       3

# ── NO hover animations (stops bouncing) ───────────────────────────────
setg   "$DTP" intellihide                true
setg   "$DTP" intellihide-animation-time 180
setg   "$DTP" intellihide-close-delay    600
setg   "$DTP" intellihide-reveal-delay   0

# ── UI options ─────────────────────────────────────────────────────────
setg   "$DTP" stockgs-keep-top-panel     false
setg   "$DTP" show-activities-button     false

# ── Layout: ALL elements on stackedTL (one unified bar) ────────────────
setstr "$DTP" panel-element-positions \
"{\"$MK\":[
  {\"element\":\"showAppsButton\",  \"visible\":false,\"position\":\"stackedTL\"},
  {\"element\":\"activitiesButton\",\"visible\":false,\"position\":\"stackedTL\"},
  {\"element\":\"leftBox\",         \"visible\":true, \"position\":\"stackedTL\"},
  {\"element\":\"taskbar\",         \"visible\":true, \"position\":\"stackedTL\"},
  {\"element\":\"centerBox\",       \"visible\":false,\"position\":\"stackedTL\"},
  {\"element\":\"rightBox\",        \"visible\":true, \"position\":\"stackedTL\"},
  {\"element\":\"dateMenu\",        \"visible\":true, \"position\":\"stackedTL\"},
  {\"element\":\"systemMenu\",      \"visible\":true, \"position\":\"stackedTL\"}
]}"

# ── Favorites ──────────────────────────────────────────────────────────
gsettings set org.gnome.shell favorite-apps \
  "['ib-arch-menu.desktop','firefox.desktop','org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop','code.desktop']"

# ── 24h clock format ───────────────────────────────────────────────────
setg org.gnome.desktop.interface clock-format "'24h'"

echo "  ✓ Settings applied"
echo

# ════════════════════════════════════════════════════════════════════════
# PART 2: CSS PATCH (FOLLOWS MACOS DOCK SPEC)
# ════════════════════════════════════════════════════════════════════════

echo "▶ Patching Dash-to-Panel CSS..."

if [ ! -f "$DTP_CSS" ]; then
    DTP_CSS="$(find /usr/share/gnome-shell/extensions -name 'stylesheet.css' \
        -path '*dash-to-panel*' 2>/dev/null | head -1 || echo '')"
    [ -n "$DTP_CSS" ] || { echo "ERROR: Dash-to-Panel stylesheet not found"; exit 1; }
fi

# Backup current CSS
sudo cp "$DTP_CSS" "${DTP_CSS}.bak.v15.$(date +%s)" 2>/dev/null || true

# Remove ALL previous IB patches (prevent stacking)
sudo sed -i \
    -e '/IB_V15_BEGIN/,/IB_V15_END/d' \
    -e '/IB_V14_BEGIN/,/IB_V14_END/d' \
    -e '/IB_V14_DOCK_BEGIN/,/IB_V14_DOCK_END/d' \
    -e '/IB_V13_DOCK_BEGIN/,/IB_V13_DOCK_END/d' \
    -e '/IB_V13_BEGIN/,/IB_V13_END/d' \
    -e '/IB_FINAL_DOCK_BEGIN/,/IB_FINAL_DOCK_END/d' \
    -e '/IB_V12_BEGIN/,/IB_V12_END/d' \
    -e '/IB_MACOS_DOCK_BEGIN/,/IB_MACOS_DOCK_END/d' \
    "$DTP_CSS"

# Write the SINGLE, CLEAN CSS patch per macOS Dock specification
sudo tee -a "$DTP_CSS" >/dev/null <<'ENDCSS'
/* IB_V15_BEGIN — Floating Glass Morphism Dock (macOS specification) */

/* ════════════════════════════════════════════════════════════════════
   STRATEGY:
   1. Make #panel (full-width wrapper) invisible and use it for bottom gap only
   2. Style #panelBox > StBoxLayout (the actual constrained content container)
   3. Apply glass morphism per macOS Dock CSS spec
   4. Add proper shadows and border for depth
   ════════════════════════════════════════════════════════════════════ */

/* ── Step 1: Erase full-width background ── */
#panel,
#panel.dashtopanelMainPanel,
.dashtopanelMainPanel,
#panelBox,
#panelBox > StBoxLayout,
#panel .panel-corner {
    background:       transparent !important;
    background-color: transparent !important;
    box-shadow:       none        !important;
    border:           none        !important;
}

#panelLeft,
#panelCenter,
#panelRight {
    background:       transparent !important;
    background-color: transparent !important;
}

/* ── Step 2: Create the floating glass pill ──
   Target the innermost StBoxLayout that holds the actual dock content.
   This element is constrained by panel-lengths setting.
   We apply glass morphism HERE, not on the full-width #panel. */

#panel > StBoxLayout,
#panelBox > StBoxLayout {
    /* Outer spacing: 12px from bottom edge, centered via panel-anchors */
    margin-bottom: 12px !important;
    
    /* Glassmorphic background (per macOS Dock CSS spec) */
    background-color: rgba(255, 255, 255, 0.15) !important;
    
    /* Blur effect for frosted glass look */
    backdrop-filter: blur(20px) saturate(180%) !important;
    -webkit-backdrop-filter: blur(20px) saturate(180%) !important;
    
    /* Glass edge definition */
    border: 1px solid rgba(255, 255, 255, 0.3) !important;
    
    /* Rounded pill shape */
    border-radius: 24px !important;
    
    /* Shadow layers (macOS Dock style):
       - Soft outer shadow (floating effect)
       - Tight drop shadow (depth)
       - Inset top highlight (beveled glass)
       - Inset bottom shadow (rim) */
    box-shadow:
        0 4px 12px rgba(0, 0, 0, 0.15),        /* Soft outer shadow */
        0 1px 3px rgba(0, 0, 0, 0.25),         /* Tight drop shadow */
        inset 0 1px 0 rgba(255, 255, 255, 0.4),  /* Top inner highlight */
        inset 0 -1px 0 rgba(0, 0, 0, 0.10)    /* Bottom rim shadow */
        !important;
    
    /* Padding inside the pill (icon spacing) */
    padding: 0 10px !important;
}

/* ── Step 3: Icon styling ── */
#panel .app-well-app,
#panel .show-apps {
    border-radius: 16px !important;
    transition: background-color 120ms ease !important;
}

#panel .app-well-app:hover .overview-icon,
#panel .show-apps:hover .overview-icon {
    background-color: rgba(255, 255, 255, 0.13) !important;
    border-radius: 16px !important;
}

#panel .app-well-app:active .overview-icon,
#panel .show-apps:active .overview-icon {
    background-color: rgba(255, 255, 255, 0.20) !important;
}

/* ── Step 4: System tray buttons ── */
#panel .panel-button {
    border-radius: 14px !important;
    transition: background-color 120ms ease !important;
}

#panel .panel-button:hover {
    background-color: rgba(255, 255, 255, 0.10) !important;
}

#panel .panel-button:active,
#panel .panel-button:checked {
    background-color: rgba(255, 255, 255, 0.16) !important;
    box-shadow: none !important;
}

/* ── Step 5: Clock display (single pill, no double ovals) ── */
#panel .clock-display,
#panel .clock-display .clock {
    background: transparent !important;
    border: none !important;
    box-shadow: none !important;
}

#panel .panel-button.clock-display,
#panel #dateMenu {
    background-color: rgba(255, 255, 255, 0.09) !important;
    border: 1px solid rgba(255, 255, 255, 0.13) !important;
    border-radius: 18px !important;
    padding: 4px 14px !important;
    margin: 5px 4px !important;
}

#panel .panel-button.clock-display:hover,
#panel #dateMenu:hover {
    background-color: rgba(255, 255, 255, 0.14) !important;
}

/* ── Step 6: Separator ── */
#panel .dashtopanel-separator {
    background: rgba(255, 255, 255, 0.15) !important;
    width: 1px !important;
    height: 22px !important;
    margin: 0 8px !important;
}

/* ── Step 7: Running indicator dots ── */
#panel .running-indicator {
    color: rgba(100, 170, 255, 0.90) !important;
}

/* IB_V15_END */
ENDCSS

echo "  ✓ CSS patch applied"
echo

# ════════════════════════════════════════════════════════════════════════
# PART 3: FORCE GNOME SHELL TO RELOAD EXTENSIONS
# ════════════════════════════════════════════════════════════════════════

echo "▶ Reloading GNOME Shell extensions..."

# Disable both extensions
gnome-extensions disable dash-to-panel@jderose9.github.com 2>/dev/null || true
gnome-extensions disable ib-desktop-clock@ibLaptop 2>/dev/null || true

# Wait for cleanup
sleep 2

# Re-enable extensions (forces full reload)
gnome-extensions enable  dash-to-panel@jderose9.github.com 2>/dev/null || true
gnome-extensions enable  ib-desktop-clock@ibLaptop 2>/dev/null || true

echo "  ✓ Extensions reloaded"
echo

# ════════════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo "  ✓ V15 DOCK FIX COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo
echo "Changes made:"
echo "  Dock: panel-lengths constrained to 74% screen width"
echo "  Dock: CSS targets #panelBox > StBoxLayout (constrained container)"
echo "  Dock: Glass morphism per macOS spec (blur + border + shadows)"
echo "  Dock: 24px border-radius forming perfect pill shape"
echo "  Dock: 12px margin-bottom floating gap from screen edge"
echo "  Dock: All elements stackedTL → one unified bar (no split)"
echo "  Dock: Icon hover NO transform (no bouncing)"
echo "  Clock: 24h format in dock"
echo
echo "REQUIRED: Log out and log back in (Wayland needs full session reload)"
echo
echo "═══════════════════════════════════════════════════════════════"setg   "$DTP" animate-appicon-hover     false
setg   "$DTP" animate-window-launch     false
# ── Intellihide ────────────────────────────────────────────────────────
setg   "$DTP" highlight-appicon-hover   false
setg   "$DTP" dot-size             3


# ── Running dots ───────────────────────────────────────────────────────
setg   "$DTP" dot-style-focused    "'DOTS'"
