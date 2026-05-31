#!/bin/bash
# IB GNOME RICE V13 — Master installer
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/rice-v13-install.log"
: > "$LOG"

echo '╔══════════════════════════════════════════════════════╗'
echo '║         IB GNOME RICE V13 — MASTER INSTALLER         ║'
echo '╚══════════════════════════════════════════════════════╝'
echo "Log: $LOG"
echo

run_step() {
    local num="$1" name="$2" file="$3"
    echo "▶ Step $num: $name"
    if bash "$SCRIPT_DIR/$file" 2>&1 | tee -a "$LOG"; then
        echo '  ✓ Done'
    else
        echo "  ✗ $file failed. Check $LOG"
        exit 1
    fi
    echo
}

chmod +x "$SCRIPT_DIR"/*.sh
run_step 1 'Clock behaviour and compact visual fix' 01-clock-v13.sh
run_step 2 'Immediate window opacity' 02-window-opacity-v13.sh
run_step 3 'Dock glass/geometry fix' 03-dock-v13.sh
run_step 4 'Start menu and keybindings' 04-start-menu-keybindings-v13.sh
run_step 5 'Five power modes and Quick Settings' 05-power-modes-v13.sh
run_step 6 'Verify status' 06-verify-v13.sh

echo '════════════════════════════════════════════════════════'
echo 'V13 installation complete.'
echo 'On Wayland, log out and log back in to reload GNOME Shell extensions.'
echo 'Then run: cat ~/rice-v13-status.txt'
echo '════════════════════════════════════════════════════════'
