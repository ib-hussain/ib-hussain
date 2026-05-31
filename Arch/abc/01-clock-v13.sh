#!/bin/bash
# IB GNOME RICE V13 — Script 01: Clock behaviour and visual fix
# Fixes: smaller height, 58px time, 18px from top, 650ms fade-in, instant hide, Super+D detection.
set -euo pipefail

EXT_BASE="$HOME/.local/share/gnome-shell/extensions"
CLOCK_UUID='ib-desktop-clock@ibLaptop'
CLOCK_DIR="$EXT_BASE/$CLOCK_UUID"
mkdir -p "$CLOCK_DIR"

cat > "$CLOCK_DIR/metadata.json" <<'JSON'
{
  "uuid": "ib-desktop-clock@ibLaptop",
  "name": "IB Desktop Clock v13",
  "description": "Compact top-centred desktop clock with instant hide and controlled fade-in.",
  "shell-version": ["44","45","46","47","48","49","50"],
  "session-modes": ["user"]
}
JSON

cat > "$CLOCK_DIR/stylesheet.css" <<'CSS'
/* IB Desktop Clock v13 — compact bubbly top card */
.ib-clock-container {
    background: transparent;
}

.ib-clock-card {
    background: rgba(8, 10, 18, 0.48);
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 26px;
    padding: 13px 36px 15px 36px;
    min-width: 265px;
    box-shadow:
        0 18px 46px rgba(0, 0, 0, 0.48),
        0 5px 16px rgba(0, 0, 0, 0.34),
        inset 0 1px 0 rgba(255, 255, 255, 0.10),
        inset 0 -1px 0 rgba(255, 255, 255, 0.04);
}

.ib-clock-day-badge {
    font-family: "Noto Sans", "Ubuntu", sans-serif;
    font-size: 9px;
    font-weight: 700;
    color: rgba(120, 180, 255, 0.92);
    letter-spacing: 2.3px;
    text-transform: uppercase;
    text-align: center;
    margin-bottom: 1px;
}

.ib-clock-time {
    font-family: "Noto Sans", "Ubuntu", sans-serif;
    font-size: 58px;
    font-weight: 300;
    color: rgba(255, 255, 255, 0.96);
    letter-spacing: -1.2px;
    text-shadow: 0 2px 18px rgba(0, 0, 0, 0.55);
    text-align: center;
}

.ib-clock-separator {
    width: 42px;
    height: 1px;
    background: rgba(255, 255, 255, 0.16);
    margin: 2px auto 5px auto;
}

.ib-clock-date {
    font-family: "Noto Sans", "Ubuntu", sans-serif;
    font-size: 13px;
    font-weight: 400;
    color: rgba(255, 255, 255, 0.70);
    letter-spacing: 0.35px;
    text-align: center;
}

.ib-clock-card:hover,
.ib-clock-time:hover,
.ib-clock-date:hover,
.ib-clock-day-badge:hover {
    background: inherit;
    transition: none;
}
CSS

cat > "$CLOCK_DIR/extension.js" <<'JS'
import St from 'gi://St';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';
import Meta from 'gi://Meta';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const MODE_FILE = `${GLib.get_home_dir()}/.config/ib-rice/power-mode`;

function ordinal(n) {
    const mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return `${n}th`;
    switch (n % 10) {
        case 1: return `${n}st`;
        case 2: return `${n}nd`;
        case 3: return `${n}rd`;
        default: return `${n}th`;
    }
}

function currentMode() {
    try {
        const [, bytes] = GLib.file_get_contents(MODE_FILE);
        return new TextDecoder().decode(bytes).trim().toLowerCase();
    } catch {
        return 'normal';
    }
}

function fastMode() {
    const mode = currentMode();
    return mode === 'turbo' || mode === 'performance';
}

function hasVisibleNormalWindow() {
    for (const actor of global.get_window_actors()) {
        const win = actor?.meta_window;
        if (!win) continue;
        if (win.minimized || win.skip_taskbar) continue;
        try {
            if (win.get_window_type() !== Meta.WindowType.NORMAL) continue;
        } catch {
            continue;
        }
        try {
            if (win.is_hidden && win.is_hidden()) continue;
        } catch {}
        try {
            if (!win.showing_on_its_workspace()) continue;
        } catch {}
        try {
            if (!actor.visible || !actor.mapped) continue;
        } catch {}
        return true;
    }
    return false;
}

export default class IbDesktopClock extends Extension {
    enable() {
        this._visible = false;
        this._signals = [];
        this._windowSignals = new Map();

        this._card = new St.BoxLayout({
            style_class: 'ib-clock-card',
            vertical: true,
            reactive: false,
            track_hover: false,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
        });

        this._dayBadge = new St.Label({ style_class: 'ib-clock-day-badge', x_align: Clutter.ActorAlign.CENTER });
        this._timeLabel = new St.Label({ style_class: 'ib-clock-time', x_align: Clutter.ActorAlign.CENTER });
        this._sep = new St.Widget({ style_class: 'ib-clock-separator' });
        this._dateLabel = new St.Label({ style_class: 'ib-clock-date', x_align: Clutter.ActorAlign.CENTER });

        this._card.add_child(this._dayBadge);
        this._card.add_child(this._timeLabel);
        this._card.add_child(this._sep);
        this._card.add_child(this._dateLabel);

        this._container = new St.Widget({
            style_class: 'ib-clock-container',
            reactive: false,
            track_hover: false,
            opacity: 0,
            visible: false,
        });
        this._container.add_child(this._card);
        Main.layoutManager.uiGroup.add_child(this._container);

        const disp = global.display;
        const wm = global.workspace_manager;
        const lay = Main.layoutManager;
        this._signals.push([disp, disp.connect('window-created', (_, win) => { this._watchWindow(win); this._syncNow(); })]);
        this._signals.push([disp, disp.connect('notify::focus-window', () => this._syncNow())]);
        this._signals.push([disp, disp.connect('restacked', () => this._syncNow())]);
        this._signals.push([wm, wm.connect('active-workspace-changed', () => this._syncNow())]);
        this._signals.push([lay, lay.connect('monitors-changed', () => this._syncNow())]);

        for (const actor of global.get_window_actors()) {
            if (actor?.meta_window) this._watchWindow(actor.meta_window);
        }

        this._textTimer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._updateText();
            return GLib.SOURCE_CONTINUE;
        });

        /* Poll lightly so Super+D / show-desktop state is caught even when Mutter does not emit a useful window signal. */
        this._syncTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT_IDLE, 250, () => {
            this._syncNow();
            return GLib.SOURCE_CONTINUE;
        });

        this._updateText();
        this._syncNow();
    }

    disable() {
        if (this._textTimer) GLib.source_remove(this._textTimer);
        if (this._syncTimer) GLib.source_remove(this._syncTimer);
        for (const [obj, id] of this._signals ?? []) {
            try { obj.disconnect(id); } catch {}
        }
        for (const [win, ids] of this._windowSignals ?? new Map()) {
            for (const id of ids) {
                try { win.disconnect(id); } catch {}
            }
        }
        this._windowSignals?.clear();
        this._container?.destroy();
        this._container = null;
    }

    _watchWindow(win) {
        if (!win || this._windowSignals.has(win)) return;
        const ids = [];
        for (const signal of ['notify::minimized', 'unmanaged']) {
            try { ids.push(win.connect(signal, () => this._syncNow())); } catch {}
        }
        this._windowSignals.set(win, ids);
    }

    _updateText() {
        if (!this._card) return;
        const now = GLib.DateTime.new_now_local();
        const day = parseInt(now.format('%d'), 10);
        this._dayBadge.set_text(now.format('%A').toUpperCase());
        this._timeLabel.set_text(`${now.format('%H')}:${now.format('%M')}`);
        this._dateLabel.set_text(`${ordinal(day)} ${now.format('%B')}, ${now.format('%Y')}`);
    }

    _syncNow() {
        if (!this._container) return;
        const shouldShow = !hasVisibleNormalWindow();
        if (!shouldShow) {
            if (this._visible || this._container.opacity !== 0) this._hideNow();
            return;
        }
        this._reposition();
        if (!this._visible) this._showSmooth();
    }

    _reposition() {
        const m = Main.layoutManager.primaryMonitor;
        if (!m || !this._card || !this._container) return;
        this._card.queue_relayout();
        const [minW, natW] = this._card.get_preferred_width(-1);
        const [minH, natH] = this._card.get_preferred_height(natW);
        const cw = Math.max(natW, minW, 265);
        const ch = Math.max(natH, minH, 110);
        const x = Math.round(m.x + (m.width - cw) / 2);
        const y = Math.round(m.y + 18);
        this._container.set_position(x, y);
        this._container.set_size(cw, ch);
    }

    _hideNow() {
        this._visible = false;
        try { this._container.remove_all_transitions(); } catch {}
        this._container.opacity = 0;
        this._container.visible = false;
    }

    _showSmooth() {
        this._visible = true;
        this._container.visible = true;
        try { this._container.remove_all_transitions(); } catch {}
        if (fastMode()) {
            this._container.opacity = 255;
            return;
        }
        this._container.opacity = 0;
        this._container.ease({
            opacity: 255,
            duration: 650,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
        });
    }
}
JS

python3 - <<'PY'
import ast, subprocess
schema = 'org.gnome.shell'
key = 'enabled-extensions'
ext = 'ib-desktop-clock@ibLaptop'
raw = subprocess.check_output(['gsettings', 'get', schema, key], text=True).strip()
try:
    vals = ast.literal_eval(raw)
except Exception:
    vals = []
if ext not in vals:
    vals.append(ext)
subprocess.run(['gsettings', 'set', schema, key, str(vals).replace('"', "'")], check=True)
PY

gnome-extensions enable "$CLOCK_UUID" 2>/dev/null || true

echo '01 ✓ Clock v13 installed: 58px time, compact height, 18px top, instant hide, 650ms fade-in, Super+D-safe.'
