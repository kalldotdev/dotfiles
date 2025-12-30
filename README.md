# Hyprland Dotfiles

A comprehensive, interactive dotfiles suite for **Arch-based Linux systems** (Arch Linux, EndeavourOS, etc.). Features a fully configured Hyprland desktop with consistent Catppuccin Mocha theming, automated management scripts, and robust backup systems.

> [!IMPORTANT]
> **Font**: Now uses **Geist Mono Nerd Font** (previously JetBrains Mono).

## Features

- **Hyprland**: Dynamic tiling Wayland compositor.
- **Interactive Installer**: Granular control over what to install (terminals, shells, browsers, etc.).
- **Consistent Theming**: **Catppuccin Mocha** applied everywhere (GTK, QT, Waybar, Terminals).
- **Core Apps**: Waybar, Wofi/Rofi, Mako/Dunst, Hyprlock, Hypridle.
- **Productivity**: Thunar (with plugins), Grim/Slurp (screenshots), Clipboard history.
- **Networking**: TUI-based bluetooth (`bluetui`) and network (`impala`) management.
- **Automation**: Scripts for installing, applying configs, and backing up to Git.

---

## Quick Start

### 1. Installation (New System)

Clone the repository and run the interactive installer:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

**What happens next?**
1. **Interactive Menu**: You will be asked to select components:
   - **Terminals**: `kitty`, `alacritty`, `ghostty`
   - **Browsers**: `zen`, `firefox`, `chrome`, `edge`, `brave`, `chromium`
   - **Media**: `mpv`, `vlc`, `celluloid`
   - **Shells**: `zsh`, `bash`, `fish`
   - **Core Components**: Toggle groups like Theming, Networking, or Development.
2. **System Update**: Runs `pacman -Syu`.
3. **Installation**: Installs selected packages (official + AUR via `yay`/`paru`).
4. **Configuration**: Backs up existing files and applies new configs.

> **Tip**: Use `./install.sh --dry-run` to preview actions without making changes.

### 2. Update Configurations (Existing Setup)

If you made changes to the repo and want to apply them to your system:

```bash
./apply.sh
```

- **Interactive**: Select exactly which configs to update (e.g., only `waybar` and `hypr`).
- **Safe**: Automatically creates a backup in `~/.config_backup_TIMESTAMP/` before overwriting.

### 3. Backup & Sync

To back up your current system configurations back to this repository and push to GitHub:

```bash
./backup.sh
```

- **Syncs**: Copies files from `~/.config/` → `~/dotfiles/config/`.
- **Git**: Automatically stages, commits, and pushes changes (interactively).

---

## Repository Structure

```tree
dotfiles/
├── config/              # Configuration sources
│   ├── hypr/           # Window manager & lockscreen
│   ├── waybar/         # Status bar
│   ├── alacritty/      # Terminal 1
│   ├── ghostty/        # Terminal 2
│   ├── wofi/           # Launcher
│   ├── rofi/           # Alternative launcher
│   ├── mako/           # Notifications
│   ├── dunst/          # Alternative notifications
│   ├── go-pray/        # Prayer times utility
│   └── wlogout/        # Logout menu
├── install.sh          # Main interactive installer
├── apply.sh            # Config applicator
├── backup.sh           # Git sync & backup tool
├── packages.txt        # Reference list of packages
└── README.md           # Documentation
```

## Key Bindings

| Keybinding | Action |
|------------|--------|
| `SUPER + Return` | Open Terminal |
| `SUPER + Space` | App Launcher (Wofi/Rofi) |
| `SUPER + E` | File Manager (Thunar) |
| `SUPER + B` | Browser |
| `SUPER + Q` | Close Window |
| `SUPER + L` | Lock Screen |
| `SUPER + Backspace` | Power Menu (Wlogout) |
| `SUPER + V` | Clipboard History |
| `SUPER + Print` | Screenshot (Fullscreen) |
| `SUPER + SHIFT + Print` | Screenshot (Region) |
| `SUPER + [1-0]` | Switch Workspace |
| `SUPER + SHIFT + [1-0]` | Move Window to Workspace |

> Check `config/hypr/hyprland.conf` for the full list.

## customization

### Apps & Packages
Edit `install.sh` to modify the default package lists or groups. The script is modular, so you can easily add new categories.

### Theming
- **GTK**: Managed via `nwg-look` (Catppuccin Mocha Standard).
- **QT**: Managed via `qt6ct`.
- **Cursor**: Qogir.
- **Icons**: Tela Circle (or similar).

### Wallpapers
Place wallpapers in `~/.config/hypr/wallpapers/` and update `hyprpaper.conf`.

---

## Troubleshooting

**"Command not found"**
Ensure the script is executable:
```bash
chmod +x install.sh apply.sh backup.sh
```

**Hyprland crashes / won't start**
- Check logs: `cat $XDG_RUNTIME_DIR/hypr/hyprland.log`
- Verify you have a compliant Wayland GPU driver (especially Nvidia users need `nvidia-drm.modeset=1`).

**Waybar missing modules**
- Ensure font `otf-geist-mono-nerd` is installed.
- Reload: `pkill waybar && waybar &`

## License
MIT / Personal Use. Feel free to fork and adapt.
