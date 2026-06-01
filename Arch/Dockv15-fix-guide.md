# IB GNOME RICE V15 — DOCK FIX (FINAL)

## 🎯 What Was Wrong

The dock in V13/V14 rendered as a **full-width rectangular bar** instead of a **floating glass pill** because:

1. **Dash-to-Panel's `#panel` is architecturally full-width**
   - This node spans 100% of screen width by design in GNOME Shell
   - No CSS background/border tricks can shrink it
   - Previous versions tried to style this full-width wrapper → rectangular effect

2. **The `panel-lengths` setting was ignored in CSS**
   - `panel-lengths: 74` tells DtP to constrain the INTERNAL content to 74% width
   - But the CSS was being applied to the outer `#panel` (full-width)
   - This created a mismatch: constrained content inside a full-width styled wrapper

3. **Double ovals on the clock**
   - Inner `.clock-display .clock` label AND outer `#dateMenu` button both had pill styles
   - One on top of the other = double visual

## ✅ What V15 Fixes

### **Root Fix: Target the Correct Element**

```css
/* WRONG (V13/V14) — Full-width wrapper */
#panel {
    background: rgba(...);
    border-radius: 24px;
}

/* CORRECT (V15) — Constrained inner container */
#panel > StBoxLayout {
    background-color: rgba(255, 255, 255, 0.15);
    backdrop-filter: blur(20px) saturate(180%);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 24px;
    margin-bottom: 12px;
    box-shadow: /* macOS spec shadows */
}
```

The `#panel > StBoxLayout` is the **actual constrained container** that respects `panel-lengths: 74`.

### **Glass Morphism Per macOS Spec**

Following the provided README, V15 applies:

- **Background:** `rgba(255, 255, 255, 0.15)` (semi-transparent white)
- **Blur:** `backdrop-filter: blur(20px) saturate(180%)` (frosted glass)
- **Border:** `1px solid rgba(255, 255, 255, 0.3)` (glass edge)
- **Radius:** `24px` (perfect pill shape)
- **Shadows (4 layers):**
  - `0 4px 12px rgba(0,0,0,0.15)` — soft outer (floating)
  - `0 1px 3px rgba(0,0,0,0.25)` — tight drop (depth)
  - `inset 0 1px 0 rgba(255,255,255,0.4)` — top highlight (beveled)
  - `inset 0 -1px 0 rgba(0,0,0,0.10)` — bottom rim (definition)

### **Floating Gap**

```css
margin-bottom: 12px !important;
```

Creates the 12px floating gap from the screen edge (not touching).

### **One Unified Bar**

All panel elements are set to `stackedTL` (left-stacked), forcing Dash-to-Panel to render them as a **single continuous row** instead of split halves.

### **No Icon Bouncing**

Removed all `transform` rules and `animate-appicon-hover` flag, so icons stay in place on hover.

---

## 🚀 Deployment

### Step 1: Copy the script

```bash
cp dock-v15-fix.sh ~/dock-v15-fix.sh
chmod +x ~/dock-v15-fix.sh
```

### Step 2: Run it

```bash
bash ~/dock-v15-fix.sh
```

The script will:
- Configure all Dash-to-Panel gsettings (width, spacing, colors)
- Delete ALL previous CSS patches (prevents conflicts)
- Write ONE clean CSS block per macOS specification
- Reload the extensions to apply changes

### Step 3: **REQUIRED — Log out and back in**

On Wayland, you MUST restart your session for GNOME Shell to reload CSS:

```bash
# Click power icon → Log out
# Log back in
```

On X11, you can also:
```bash
Alt+F2 → type 'r' → Enter
```

---

## 📋 What You Should See

**Before (V13/V14):**
- Full-width rectangular panel at bottom
- Separate pill on right for clock/tray
- Icons bounce up on hover
- Clock shows 08 34 (colon disappears)

**After (V15):**
- ✅ Single floating glass pill at bottom-center
- ✅ 12px gap from screen edge (floating effect)
- ✅ Perfectly rounded corners (24px)
- ✅ Frosted glass appearance with blur
- ✅ Icons stay in place on hover
- ✅ Clock shows 08:34 (colon always visible)
- ✅ All icons + clock/tray in ONE unified container

---

## 🔧 How V15 Ensures Correct Reload

### **1. CSS Cleanup**

Deletes every previous `/* IB_* */` patch block before writing new CSS:

```bash
sudo sed -i \
    -e '/IB_V15_BEGIN/,/IB_V15_END/d' \
    -e '/IB_V14_BEGIN/,/IB_V14_END/d' \
    -e '/IB_V13_DOCK_BEGIN/,/IB_V13_DOCK_END/d' \
    # ... etc
    "$DTP_CSS"
```

This prevents multiple conflicting styles from stacking.

### **2. Extension Restart**

Forces full GNOME Shell CSS reload:

```bash
gnome-extensions disable dash-to-panel@jderose9.github.com
sleep 2
gnome-extensions enable  dash-to-panel@jderose9.github.com
```

### **3. Session Restart (Wayland)**

On Wayland, CSS changes don't take effect until GNOME Shell itself restarts, which happens at login.

---


### Why `#panel > StBoxLayout` and not other selectors?

- `#panel` = full-width wrapper (don't style this)

V15 uses both `#panel > StBoxLayout` and `#panelBox > StBoxLayout` to ensure compatibility across different GNOME versions.

### Why `margin-bottom: 12px` and not top padding?

- Margins create the floating gap in the rendered output
- Padding would compress the icons inward (bad UX)
- Margin-bottom on the StBoxLayout pushes the entire pill upward from the screen edge

### Why four shadow layers?

Per the macOS Dock CSS spec:

| Layer | Purpose |
|-------|---------|
| `0 4px 12px rgba(0,0,0,0.15)` | Soft outer shadow → floating effect |
| `0 1px 3px rgba(0,0,0,0.25)` | Tight drop shadow → depth/separation |
| `inset 0 1px 0 rgba(255,255,255,0.4)` | Top inner highlight → beveled glass |
| `inset 0 -1px 0 rgba(0,0,0,0.10)` | Bottom rim → glass definition |

Multiple layers create visual realism.

---

## 🐛 Troubleshooting

### Dock still rectangular after login?

1. **Verify CSS was written:**
   ```bash
   grep "IB_V15_BEGIN" /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/stylesheet.css
   ```
   Should return the CSS patch. If not, re-run the script.

2. **Verify extension is enabled:**
   ```bash
   gnome-extensions list --enabled | grep dash-to-panel
   ```

3. **Verify gsettings:**
   ```bash
   gsettings get org.gnome.shell.extensions.dash-to-panel panel-lengths
   ```
   Should return `{'0':'74'}` (or similar monitor key).

4. **Force full reload:**
   ```bash
   gnome-extensions disable dash-to-panel@jderose9.github.com
   sleep 2
   gnome-extensions enable dash-to-panel@jderose9.github.com
   gnome-extensions disable ib-desktop-clock@ibLaptop
   sleep 2
   gnome-extensions enable ib-desktop-clock@ibLaptop
   ```
   Then log out and back in.

### Dock is floating but looks too transparent?

Edit the CSS in the stylesheet and change opacity:

```bash
# Current (V15)
background-color: rgba(255, 255, 255, 0.15);

# More opaque
background-color: rgba(255, 255, 255, 0.25);

# Less opaque
background-color: rgba(255, 255, 255, 0.10);
```

Then reload extensions.

### Clock shows in two places or not at all?

The fix sets `panel-element-positions` to all `stackedTL`. Verify:

```bash
gsettings get org.gnome.shell.extensions.dash-to-panel panel-element-positions
```

All entries should show `"stackedTL"`. If any show `"stackedBR"`, re-run the script.

---

## 📚 Related Files

- **macOS Dock CSS README** — The specification this V15 follows
- **dock-v15-fix.sh** — The main fix script
- **V13_COMPLETE_GUIDE.md** — Full rice documentation (still valid for other components)

---

## 🎉 Expected Result

After deployment and login, you'll have:

✅ **True floating glass pill dock** (not rectangular panel)
✅ **Perfect 24px rounded corners** (pill shape)
✅ **12px gap from screen bottom** (floating effect)
✅ **Frosted glass appearance** (blur + transparency)
✅ **One unified bar** (apps + clock + tray together)
✅ **No icon bouncing** (clean on-hover effect)
✅ **24h clock format** (08:34 not 8:34 AM)
✅ **Professional aesthetic** (matches macOS design language)

---

## 🔄 Version History

- **V13:** Attempted floating dock with basic CSS
- **V14:** Tried margin approach on full-width panel
- **V15:** **CORRECT** — Targets constrained inner container, follows macOS spec

This is the final, production-ready dock fix. 🚀- `#panelBox` = layout container (target here)
- `#panelBox > StBoxLayout` = the ACTUAL content box (also target this)
- `#dashtopanelScrollview` = icon scroll area (don't target; part of taskbar)

