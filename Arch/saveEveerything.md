Yes. The cleanest route is **not ISO first**. The best route is:

**Keep your base Arch install scripts as the OS installer, then create one portable “rice pack” folder/repo that runs after first boot.**

Your current base scripts already do the hard OS work: partitioning/pacstrap in the UEFI/BIOS installers, then locale, hostname, user, bootloader, NetworkManager, pyenv, and sudo setup in the chroot scripts.   The rice should be a separate post-install layer because GNOME extensions, themes, AUR packages, dock settings, icon overrides, wallpapers, and user dconf settings are user-session-level things, not base OS things.

## Best structure: `ArchRicePack`

Create a folder/repo like this:

```text
ArchRicePack/
├── README.md
├── install-rice.sh
├── packages/
│   ├── pacman-packages.txt
│   └── aur-packages.txt
├── configs/
│   ├── bashrc
│   ├── bash_profile
│   ├── fastfetch/
│   ├── autostart/
│   ├── icons/
│   └── dconf/
│       ├── gnome-interface.ini
│       ├── gnome-shell.ini
│       ├── dash-to-dock.ini
│       └── keybindings.ini
├── assets/
│   ├── wallpapers/
│   └── arch-icons/
└── scripts/
    ├── 01-install-gnome-theme.sh
    ├── 02-install-extensions.sh
    ├── 03-apply-dconf.sh
    ├── 04-setup-terminal.sh
    └── 05-final-verify.sh
```

The important idea: after your UEFI/BIOS install and chroot scripts finish, you reboot, log in as `ibrahim`, then run:

```bash
git clone YOUR_REPO_URL ~/ArchRicePack && cd ~/ArchRicePack && bash install-rice.sh
```

That is the correct reusable system.

## Capture the current working rice now

Run this on the VM while the system is in the stable state:

```bash
mkdir -p ~/ArchRicePack/{packages,configs/dconf,configs/fastfetch,configs/autostart,configs/icons,assets/wallpapers,assets/arch-icons,scripts}
```

Export installed package lists:

```bash
pacman -Qqen > ~/ArchRicePack/packages/pacman-packages.txt && pacman -Qqem > ~/ArchRicePack/packages/aur-packages.txt
```

Export GNOME/Dash/keybinding settings:

```bash
dconf dump /org/gnome/desktop/interface/ > ~/ArchRicePack/configs/dconf/gnome-interface.ini && dconf dump /org/gnome/desktop/wm/ > ~/ArchRicePack/configs/dconf/gnome-wm.ini && dconf dump /org/gnome/shell/ > ~/ArchRicePack/configs/dconf/gnome-shell.ini && dconf dump /org/gnome/shell/extensions/dash-to-dock/ > ~/ArchRicePack/configs/dconf/dash-to-dock.ini && dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > ~/ArchRicePack/configs/dconf/keybindings.ini
```

Copy terminal and fastfetch configuration:

```bash
cp -a ~/.bashrc ~/ArchRicePack/configs/bashrc && cp -a ~/.bash_profile ~/ArchRicePack/configs/bash_profile && cp -a ~/.config/fastfetch/. ~/ArchRicePack/configs/fastfetch/
```

Copy local icon overrides:

```bash
cp -a ~/.local/share/icons/. ~/ArchRicePack/configs/icons/ 2>/dev/null || true
```

Copy autostart files, but only if you want to preserve them:

```bash
cp -a ~/.config/autostart/. ~/ArchRicePack/configs/autostart/ 2>/dev/null || true
```

Copy your wallpaper folder into the rice pack. Replace the source path with your actual wallpaper directory:

```bash
cp -a ~/Pictures/. ~/ArchRicePack/assets/wallpapers/ 2>/dev/null || true
```

Then put your final working script into the repo:

```bash
cp ~/phase13_final_rice_fix.sh ~/ArchRicePack/scripts/05-final-verify.sh
```

## ISO vs post-install script

Use **post-install script first**. It is faster, safer, and reusable on real hardware, VMs, UEFI, and BIOS installs. Your current install scripts already differ for UEFI/GPT and BIOS/MBR, so keeping the rice separate avoids mixing bootloader/disk logic with GNOME user-session logic.  

A custom ISO is possible with **archiso**. Archiso’s `releng` profile is the same kind of profile used for the official Arch installation ISO and can be copied/customised as a starting point. ([Arch Wiki][1]) But that ISO should only embed your installer scripts and rice pack; it should not try to snapshot the exact VM desktop as a universal installed OS.

The recommended order is:

```text
Stage 1: Keep install-uefi.sh / install-bios.sh
Stage 2: Keep chroot-uefi.sh / chroot-bios.sh
Stage 3: Add ArchRicePack/install-rice.sh
Stage 4: Optional later — build custom Arch ISO using archiso that includes all scripts
```

## Why not clone the VM directly?

A full disk image or ISO made from this VM would preserve everything, but it becomes hardware-specific and messy: VirtualBox graphics, VM disk UUIDs, bootloader assumptions, user machine names, and GNOME extension state may not transfer cleanly. Use that only as a **backup image**, not as the generic installer.

## Next thing I would do

Turn the current working state into `ArchRicePack/install-rice.sh`, then later we can plug it into your existing UEFI/BIOS flow so the full rebuild becomes:

```bash
bash install-uefi.sh
arch-chroot /mnt
bash chroot-uefi.sh
reboot
git clone <your-rice-repo>
bash install-rice.sh
```

That is the professional route. It gives you a reproducible Arch rice without turning your VM into a fragile one-off image.

[1]: https://wiki.archlinux.org/title/Archiso?utm_source=chatgpt.com "archiso - ArchWiki"
