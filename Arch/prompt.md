# MASTER PROMPT: Custom Arch Linux Desktop Developer Environment Setup

## SYSTEM OVERVIEW
I am building a custom Arch Linux system that combines the visual aesthetics of GNOME/macOS with the tiling capabilities of Hyprland, using Enlightenment (E) as the base desktop environment. The system should be a highly personalized hybrid that I control entirely through configuration files.

## USER & PERMISSIONS
- **Username:** ibrahim
- **Privileges:** Complete root-level access without requiring sudo for any command
- **Goal:** I want to operate as root-equivalent user seamlessly, touching and modifying any file without permission barriers

## CORE PHILOSOPHY
I want complete control over every aspect of my desktop through direct configuration file manipulation. I will not rely on GUI settings panels. I will manually edit config files for everything. The desktop should be built from modular components that I can mix, match, and replace at will.

## DESKTOP ENVIRONMENT: ENLIGHTENMENT (E)
- **Why Enlightenment:** It allows pixel-perfect customization through EDC/EDJ theme files, supports hybrid window management (tiling + floating simultaneously), and provides modular gadgets for building custom UI components
- **Key features I'll leverage:**
  - EFL (Enlightenment Foundation Libraries) for native performance
  - EDC theme files for scripting the entire visual interface
  - Built-in compositing with blur effects
  - Gadget modules for custom panels and widgets
  - Edge bindings for custom gestures

## VISUAL LAYOUT REQUIREMENTS

### Bottom Taskbar (macOS-style dock)
- Centered application dock with icon zoom/magnification on hover
- Active application indicators (dots below running apps)
- System tray area on the right (network, volume, battery, clock)
- Transparent/blurred background matching GNOME's modern aesthetic
- Height: approximately 48-56px
- I want to manually configure which apps appear and their order

### Top Panel (GNOME-style but reversed position)
- Activities/Applications menu on the left (similar to GNOME's "Activities")
- Center: Current date and time with day/month display
- Right side: System status indicators (network, Bluetooth, volume, battery percentage)
- Panel should have subtle transparency with blur effect
- Height: approximately 28-32px
- Calendar dropdown when clicking date/time
- Notification center integration

### Desktop Features
- Dynamic wallpaper system that changes every n seconds (configurable)
- Wallpapers sourced from a local directory with smooth transitions
- Desktop icons: Show/hide toggle capability
- Right-click context menu with custom entries
- Hot corners: Top-left for overview/exposé, bottom-right for show desktop
- Support for both static and live wallpapers

### Window Management (Hyprland-inspired tiling)
- Automatic tiling for new windows by default
- Manual tiling controls: Toggle floating for any window
- Keyboard shortcuts for window manipulation
- Gaps between tiled windows (configurable: 4-8px default)
- Workspace/virtual desktop switching with animations
- Window snapping to screen edges and corners
- Tiling layouts: Master-stack, grid, columns, rows

## LOCKSCREEN WITH DYNAMIC WALLPAPER
- Custom lockscreen that cycles through a wallpaper collection
- Wallpaper change interval: Configurable (default: 30 seconds)
- Smooth fade transition between wallpapers
- Blur effect on lockscreen background (configurable intensity)
- Clock display: Large, centered digital clock with date
- Customizable clock font, size, and color
- Password input field with subtle styling matching the overall theme
- Keyboard layout indicator
- Power options: Shutdown, restart, suspend (with confirmation)
- Media player controls if music is playing
- Notification preview: Show recent notifications on lockscreen
- Wallpaper source: Local directory path, recursive scanning
- Support for different wallpapers on different workspaces if possible
- No branding or logos on lockscreen

## THEME CONSISTENCY
- Unified GTK/Qt theme across all applications
- Consistent icon theme throughout the system
- Matching cursor theme
- Terminal color scheme that complements the desktop theme
- Font configuration: Custom system-wide fonts (specify in config)

## TECHNICAL IMPLEMENTATION DETAILS

### Configuration Files I'll Create/Modify
1. **Enlightenment theme files (.edc):** Custom bottom dock, top panel, window decorations
2. **Window manager rules:** Tiling behavior, gaps, workspaces
3. **Compositor settings:** Blur strength, transparency levels, animations
4. **Keyboard shortcuts file:** All custom keybindings
5. **Lockscreen configuration:** Wallpaper cycling script, blur settings, clock styling
6. **Startup applications script:** Auto-start programs and scripts
7. **Environment variables:** PATH, XDG directories, custom variables
8. **Display settings:** Resolution, refresh rate, multi-monitor arrangements
9. **Input device configuration:** Touchpad gestures, mouse acceleration
10. **Notification daemon configuration:** Position, duration, styling

### Required Packages (to be installed)
- **Base:** Enlightenment, EFL, Terminology (Enlightenment's terminal)
- **Display:** Xorg server, LightDM (display manager with Enlightenment support)
- **Graphics:** Graphics drivers (specific to hardware), mesa
- **Audio:** PipeWire/PulseAudio with pavucontrol
- **Network:** NetworkManager with applet
- **Utilities:** Compositor tools, screenshot tool, clipboard manager
- **Fonts:** Custom font packages (specify preferred fonts)

## PYTHON ENVIRONMENT
- Python 3.12.7 installed either from source or via pyenv
- Located at /usr/local/python3.12/ or managed through pyenv
- pip fully functional
- Virtual environment support
- I may use Python scripts for wallpaper management, lockscreen customization, etc.

## SYSTEM SPECIFICS
- **Timezone:** Pakistan/Karachi (Asia/Karachi)
- **Locale:** en_US.UTF-8
- **Hostname:** arch
- **Boot:** UEFI/GPT preferred, BIOS/MBR fallback supported
- **Partition scheme:** Separate root, swap, and EFI partitions

## CUSTOMIZATION BOUNDARIES
- I want to modify EVERYTHING through text config files - no GUI tools
- I prefer modular components that can be individually replaced
- The system should remain lightweight despite heavy customization
- Resource usage: Target under 500MB RAM at idle with full desktop loaded
- Boot time: Under 10 seconds from GRUB to desktop (on modern SSD)

## KEYBOARD SHORTCUTS I'LL CONFIGURE

## FILE STRUCTURE I EXPECT TO CREATE
```
~/.config/
├── enlightenment/
├── wallpaper-engine/
│   ├── wallpapers/
├── gtk-3.0/
├── qt5ct/
└── autostart/
    └── startup.sh
```

## AESTHETIC REFERENCES
- **Primary inspiration:** GNOME 45+ for clean modern look, macOS for dock and smooth animations
- **Secondary inspiration:** Hyprland for tiling efficiency, r/unixporn minimalist setups
- **Color palette:** Dark theme with accent colors for active elements
- **Animations:** Smooth but fast (200-400ms transitions)
- **Typography:** Clean, modern sans-serif fonts with good hinting
- **Icons:** Minimalist icon set, preferably monochrome outlines
- **Wallpaper style:** Dark-themed, atmospheric, nature, abstract, or space photography

---

## SPECIFIC QUESTIONS THE NEXT PERSON/CHAT SHOULD ADDRESS:

1. How to create an Enlightenment EDC theme that mimics a macOS-style bottom dock with magnification and a GNOME-style top panel?

2. How to implement dynamic wallpaper cycling with smooth transitions in Enlightenment, and can this be integrated with the lockscreen?

3. What is the correct Enlightenment configuration to achieve Hyprland-like automatic tiling with configurable gaps?

4. How to create a custom lockscreen for Enlightenment that supports dynamic wallpapers, blur, and custom clock styling?

5. How to properly give user 'ibrahim' complete root-equivalent access without breaking system functionality?

6. How to configure LightDM to work seamlessly with Enlightenment's custom lockscreen?

7. What Python scripts or Enlightenment modules can I use to manage wallpaper cycling both on desktop and lockscreen?

8. How to ensure theme consistency across GTK and Qt applications when using Enlightenment as the desktop environment?

---

**End goal:** A completely personalized, file-configurable desktop environment that looks like a premium GNOME/macOS hybrid, tiles windows like Hyprland, changes wallpapers dynamically, and has a beautiful custom lockscreen - all built on the lightweight Enlightenment foundation.
