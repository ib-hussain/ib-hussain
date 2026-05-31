#!/bin/bash
# IB GNOME RICE V13 — Script 02: Immediate opacity fix
# Removes the slow window opacity transitions that made app switching feel gradual.
set -euo pipefail

EXT_BASE="$HOME/.local/share/gnome-shell/extensions"
OPACITY_UUID='ib-window-opacity@ibLaptop'
OPACITY_DIR="$EXT_BASE/$OPACITY_UUID"
mkdir -p "$OPACITY_DIR"

cat > "$OPACITY_DIR/metadata.json" <<'JSON'
{
  "uuid": "ib-window-opacity@ibLaptop",
  "name": "IB Window Opacity v13",
  "description": "Applies selective opacity instantly, with no window-switching fade.",
  "shell-version": ["44","45","46","47","48","49","50"],
  "session-modes": ["user"]
}
JSON

cat > "$OPACITY_DIR/extension.js" <<'JS'
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

const TARGET = 209; // 82% visible, applied immediately
const SYSTEM_APPS = [
    'gnome-terminal', 'org.gnome.terminal', 'terminal',
    'nautilus', 'org.gnome.nautilus', 'files',
    'code', 'code - oss', 'code-oss',
    'gedit', 'gnome-text-editor', 'org.gnome.texteditor',
    'gnome-system-monitor', 'gnome-tweaks', 'gnome-control-center',
    'evince', 'eog', 'file-roller', 'dconf-editor', 'gnome-disks',
];

function isSystemApp(win) {
    const cls = (win.get_wm_class?.() ?? '').toLowerCase();
    const inst = (win.get_wm_class_instance?.() ?? '').toLowerCase();
    const title = (win.get_title?.() ?? '').toLowerCase();
    return SYSTEM_APPS.some(s => cls.includes(s) || inst.includes(s) || title.includes(s));
}

export default class IbWindowOpacity extends Extension {
    enable() {
        this._signals = [];
        const disp = global.display;
        this._signals.push(disp.connect('window-created', (_, win) => this._applySoon(win)));
        this._signals.push(disp.connect('notify::focus-window', () => this._applyAllNow()))
        this._signals.push(disp.connect('restacked', () => this._applyAllNow()))
        this._interval = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, 2, () => {
            this._applyAllNow();
            return GLib.SOURCE_CONTINUE;
        });
        this._applyAllNow();
    }

    disable() {
        if (this._interval) GLib.source_remove(this._interval);
        for (const id of this._signals ?? []) {
            try { global.display.disconnect(id); } catch {}
        }
        for (const actor of global.get_window_actors()) {
            if (actor) actor.opacity = 255;
        }
    }

    _applySoon(win) {
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 80, () => {
            this._applyWindowNow(win);
            return GLib.SOURCE_REMOVE;
        });
    }

    _applyAllNow() {
        for (const actor of global.get_window_actors()) {
            if (actor?.meta_window) this._applyWindowNow(actor.meta_window);
        }
    }

    _applyWindowNow(win) {
        if (!win || win.minimized || win.skip_taskbar) return;
        try {
            if (win.get_window_type() !== Meta.WindowType.NORMAL) return;
        } catch {
            return;
        }
        const actor = win.get_compositor_private?.();
        if (!actor) return;
        actor.opacity = isSystemApp(win) ? TARGET : 255;
    }
}
JS

python3 - <<'PY'
import ast, subprocess
schema = 'org.gnome.shell'
key = 'enabled-extensions'
ext = 'ib-window-opacity@ibLaptop'
raw = subprocess.check_output(['gsettings', 'get', schema, key], text=True).strip()
try:
    vals = ast.literal_eval(raw)
except Exception:
    vals = []
if ext not in vals:
    vals.append(ext)
subprocess.run(['gsettings', 'set', schema, key, str(vals).replace('"', "'")], check=True)
PY

gnome-extensions enable "$OPACITY_UUID" 2>/dev/null || true

echo '02 ✓ Window opacity v13 installed: same selective transparency, but no gradual window switching.'
