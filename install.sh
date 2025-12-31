#!/bin/bash

# Dotfiles Installation Script
# Interactive installer for EndeavourOS/Arch-based systems

set -e

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="${SCRIPT_DIR}/install.log"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# Dry run mode (can be set via --dry-run)
DRY_RUN=false

# Package Categories
declare -A PKG_GROUPS
declare -A PKG_DESCRIPTIONS
declare -a GROUP_ORDER

# Define Groups
GROUP_ORDER=(
    "Core"
    "Utilities"
    "Theming"
    "Networking"
    "Development"
)

PKG_GROUPS["Core"]="hyprland hyprlock hypridle hyprpaper waybar wofi rofi dunst wlogout xdg-desktop-portal-hyprland hyprpolkitagent"
PKG_DESCRIPTIONS["Core"]="Essential Hyprland components and desktop portal"

PKG_GROUPS["Utilities"]="thunar grim slurp swappy wl-clipboard cliphist playerctl pavucontrol pamixer brightnessctl udiskie lazygit lazydocker zsh-autosuggestions zsh-syntax-highlighting pipewire wireplumber pipewire-pulse gvfs thunar-archive-plugin file-roller libnotify btop jq unzip zip"
PKG_DESCRIPTIONS["Utilities"]="File manager, screenshots, audio, shell plugins, lazy tools"

PKG_GROUPS["Theming"]="starship otf-geist-mono-nerd catppuccin-gtk-theme-mocha qogir-cursor-theme-git hypremoji qt6ct nwg-look cava"
PKG_DESCRIPTIONS["Theming"]="Fonts, themes, shell prompt, theme managers"

PKG_GROUPS["Networking"]="bluetui impala bluez bluez-utils"
PKG_DESCRIPTIONS["Networking"]="TUI/CLI Network and Bluetooth management"

PKG_GROUPS["Development"]="base-devel git"
PKG_DESCRIPTIONS["Development"]="Basic development tools"

# Optional Selection Arrays
TERMINALS=("kitty" "alacritty" "ghostty")
TERMINAL_DESCS=("GPU accelerated (Official)" "Fast & lightweight (Official)" "Sleek & modern (AUR/Official)")

BROWSERS=("zen-browser-bin" "firefox" "google-chrome" "microsoft-edge-stable-bin" "brave-bin" "chromium")
BROWSER_DESCS=("Zen (AUR)" "Firefox (Official)" "Chrome (AUR)" "Edge (AUR)" "Brave (AUR)" "Chromium (Official)")

MEDIA_PLAYERS=("mpv" "vlc" "celluloid")
MEDIA_PLAYER_DESCS=("Powerful CLI/GUI player" "Classic all-rounder" "GTK frontend for MPV")

SHELLS=("zsh" "bash")
SHELL_DESCS=("Z Shell" "Bourne Again Shell")

# AUR specific packages
AUR_PACKAGES="hyprswitch go-pray-bin catppuccin-gtk-theme-mocha qogir-cursor-theme-git hypremoji bluetui impala lazydocker otf-geist-mono-nerd zen-browser-bin google-chrome microsoft-edge-stable-bin brave-bin ghostty hyprpolkitagent"

# ==============================================================================
# UTILITIES
# ==============================================================================

log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$type] $message" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
    log "INFO" "Section: $1"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log "WARNING" "$1"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
    log "INFO" "$1"
}

# Wrapper for commands to support dry-run
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] Would execute: $*${NC}"
    else
        # Print command being executed for debugging context
        echo -e "${CYAN}Running: $*${NC}"
        "$@"
    fi
}

# ==============================================================================
# MENU SYSTEM
# ==============================================================================

# Checkbox menu function
# Usage: checkbox_menu "Title" "Option1" "Desc1" "Option2" "Desc2" ...
# Returns selected indices in SELECTED_INDICES array
checkbox_menu() {
    local title="$1"
    shift
    
    local options=()
    local descs=()
    local statuses=()
    
    while [ $# -gt 0 ]; do
        options+=("$1")
        descs+=("$2")
        statuses+=(${MENU_DEFAULT_STATE:-true})
        shift 2
    done
    
    local current=0
    local count=${#options[@]}
    
    # Hide cursor
    tput civis
    
    # Save terminal state
    tput smcup
    
    while true; do
        clear
        print_header "$title"
        echo -e "${CYAN}Use UP/DOWN to navigate, SPACE to toggle, ENTER to confirm${NC}\n"
        
        for ((i=0; i<count; i++)); do
            local cursor=" "
            local checked=" "
            local color="$NC"
            
            if [ $i -eq $current ]; then
                cursor=">"
                color="$BLUE"
            fi
            
            if [ "${statuses[$i]}" = true ]; then
                checked="x"
                if [ $i -eq $current ]; then
                     color="${GREEN}" # Green if selected and checked
                fi
            fi
            
            echo -e "${color}${cursor} [${checked}] ${options[$i]} ${NC}- ${descs[$i]}"
        done
        
        # Read input
        # IFS= prevents 'read' from stripping leading/trailing whitespace (like Space)
        if ! IFS= read -rsn1 key 2>/dev/null; then
            break
        fi
        
        if [[ $key == "" || $key == $'\n' ]]; then # Enter
            break
        elif [[ $key == " " ]]; then # Space
            if [ "${statuses[$current]}" = true ]; then
                statuses[$current]=false
            else
                statuses[$current]=true
            fi
        elif [[ $key == $'\x1b' ]]; then
            # Attempt to read remaining chars of escape sequence
            if read -rsn2 -t 0.1 key 2>/dev/null; then
                if [[ $key == "[A" || $key == "OA" ]]; then # Up
                    current=$((current-1))
                    [ $current -lt 0 ] && current=$((count-1))
                elif [[ $key == "[B" || $key == "OB" ]]; then # Down
                    current=$((current+1))
                    [ $current -ge $count ] && current=0
                fi
            fi
        fi
    done
    
    # Restore terminal state
    tput rmcup
    tput cnorm # Show cursor
    
    SELECTED_INDICES=()
    for ((i=0; i<count; i++)); do
        if [ "${statuses[$i]}" = true ]; then
            SELECTED_INDICES+=("$i")
        fi
    done
}

# ==============================================================================
# LOGIC
# ==============================================================================

check_system() {
    print_header "Checking System"
    if [ ! -f /etc/arch-release ]; then
        print_error "This script is designed for Arch-based systems."
        if [ "$DRY_RUN" = false ]; then
            exit 1
        fi
    fi
    print_success "Arch Linux detected"
    
    touch "$LOG_FILE"
    print_info "Log file: $LOG_FILE"
}

setup_aur_helper() {
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        print_warning "No AUR helper found."
        read -p "Install yay? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing yay..."
            run_cmd sudo pacman -S --needed --noconfirm git base-devel
            run_cmd git clone https://aur.archlinux.org/yay.git /tmp/yay
            run_cmd cd /tmp/yay
            run_cmd makepkg -si --noconfirm
            run_cmd rm -rf /tmp/yay
        fi
    fi
    
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    else
        print_error "No AUR helper available. Skipping AUR packages."
        AUR_HELPER=""
    fi
}

install_selected_packages() {
    local packages_to_install=()
    
    # --- Custom Selection (Multi-select) ---
    print_header "Custom Selection"
    echo -e "${CYAN}Select specific applications to install.${NC}"
    echo -e "${CYAN}You can pick multiple options for each category.${NC}\n"
    read -p "Press Enter to start selection..."
    
    MENU_DEFAULT_STATE=false
    
    # 1. Terminals
    local term_args=()
    for ((i=0; i<${#TERMINALS[@]}; i++)); do
        term_args+=("${TERMINALS[$i]}" "${TERMINAL_DESCS[$i]}")
    done
    checkbox_menu "Select Terminals" "${term_args[@]}"
    for idx in "${SELECTED_INDICES[@]}"; do
        packages_to_install+=("${TERMINALS[$idx]}")
    done
    
    # 2. Browsers
    local browser_args=()
    for ((i=0; i<${#BROWSERS[@]}; i++)); do
        browser_args+=("${BROWSERS[$i]}" "${BROWSER_DESCS[$i]}")
    done
    checkbox_menu "Select Browsers" "${browser_args[@]}"
    for idx in "${SELECTED_INDICES[@]}"; do
        packages_to_install+=("${BROWSERS[$idx]}")
    done

    # 3. Media Players
    local media_args=()
    for ((i=0; i<${#MEDIA_PLAYERS[@]}; i++)); do
        media_args+=("${MEDIA_PLAYERS[$i]}" "${MEDIA_PLAYER_DESCS[$i]}")
    done
    checkbox_menu "Select Media Players" "${media_args[@]}"
    for idx in "${SELECTED_INDICES[@]}"; do
        packages_to_install+=("${MEDIA_PLAYERS[$idx]}")
    done

    # 4. Shells
    local shell_args=()
    for ((i=0; i<${#SHELLS[@]}; i++)); do
        shell_args+=("${SHELLS[$i]}" "${SHELL_DESCS[$i]}")
    done
    checkbox_menu "Select Shells" "${shell_args[@]}"
    for idx in "${SELECTED_INDICES[@]}"; do
        packages_to_install+=("${SHELLS[$idx]}")
    done
    
    MENU_DEFAULT_STATE=true

    # --- Main Group Selection ---
    print_header "Selecting Components"
    
    # Prepare menu arguments
    local menu_args=()
    for group in "${GROUP_ORDER[@]}"; do
        menu_args+=("$group" "${PKG_DESCRIPTIONS[$group]}")
    done
    
    checkbox_menu "Select Components to Install" "${menu_args[@]}"
    
    echo -e "\n${BLUE}Selected Categories:${NC}"
    for idx in "${SELECTED_INDICES[@]}"; do
        group="${GROUP_ORDER[$idx]}"
        echo -e " - $group"
        # Split string into array
        read -ra pkgs <<< "${PKG_GROUPS[$group]}"
        packages_to_install+=("${pkgs[@]}")
    done
    
    if [ ${#packages_to_install[@]} -eq 0 ]; then
        print_warning "No packages selected."
        return
    fi
    
    echo
    read -p "Proceed with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation aborted by user."
        return
    fi
    
    print_header "Installing Packages"
    
    # Update system first
    print_info "Updating system..."
    run_cmd sudo pacman -Syu --noconfirm
    
    # Separate AUR and Repo packages
    local repo_pkgs=()
    local aur_pkgs=()
    
    for pkg in "${packages_to_install[@]}"; do
        if [[ " $AUR_PACKAGES " =~ " $pkg " ]]; then
            aur_pkgs+=("$pkg")
        else
            repo_pkgs+=("$pkg")
        fi
    done
    
    # Install Repo packages
    if [ ${#repo_pkgs[@]} -gt 0 ]; then
        print_info "Installing Official Repository Packages..."
        run_cmd sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
    fi
    
    # Install AUR packages
    if [ ${#aur_pkgs[@]} -gt 0 ] && [ -n "$AUR_HELPER" ]; then
        print_info "Installing AUR Packages..."
        run_cmd $AUR_HELPER -S --needed --noconfirm "${aur_pkgs[@]}"
    fi
    
    print_success "Package installation complete."
}

backup_and_link_configs() {
    print_header "Configuration Files"
    
    # Define config directories relative to script
    local configs=(hypr waybar rofi wofi alacritty mako wlogout go-pray ghostty dunst)
    
    read -p "Do you want to install configuration files? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    run_cmd mkdir -p "$BACKUP_DIR"
    print_info "Backup directory: $BACKUP_DIR"
    
    for conf in "${configs[@]}"; do
        local src="$SCRIPT_DIR/config/$conf"
        local dest="$HOME/.config/$conf"
        
        if [ -d "$src" ]; then
            # Backup
            if [ -d "$dest" ]; then
                print_info "Backing up $conf..."
                run_cmd cp -r "$dest" "$BACKUP_DIR/"
            fi
            
            # Install
            print_info "Installing $conf config..."
            run_cmd mkdir -p "$dest"
            run_cmd cp -r "$src/"* "$dest/"
        fi
    done
    
    # Shell configs
    if [ -f "$SCRIPT_DIR/.bashrc" ]; then
        print_info "Updating .bashrc..."
        run_cmd cp "$HOME/.bashrc" "$BACKUP_DIR/" 2>/dev/null || true
        run_cmd cp "$SCRIPT_DIR/.bashrc" "$HOME/.bashrc"
    fi
    
    # Make scripts executable
    run_cmd chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
    run_cmd chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
    
    print_success "Configurations installed."
}

post_install_steps() {
    print_header "Post-Installation"
    
    run_cmd mkdir -p "$HOME/Pictures/Screenshots"
    
    # Starship setup
    if ! grep -q "starship init bash" "$HOME/.bashrc"; then
        if [ "$DRY_RUN" = false ]; then
            echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        else
            echo "[DRY RUN] Would add starship init to .bashrc"
        fi
    fi
    
    print_success "Setup complete!"
}

uninstall_fish() {
    print_header "Legacy Shell Cleanup"
    if pacman -Qi fish &>/dev/null; then
        print_warning "Fish shell is currently installed."
        read -p "Do you want to UNINSTALL fish and switch to bash/zsh? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Uninstalling fish..."
            run_cmd sudo pacman -Rns fish --noconfirm || true
            
            # Ensure user has a valid shell
            if [[ "$SHELL" == *"fish"* ]]; then
                 if command -v zsh &>/dev/null; then
                    print_info "Switching default shell to Zsh..."
                    run_cmd chsh -s $(which zsh)
                 else
                    print_info "Switching default shell to Bash..."
                    run_cmd chsh -s /bin/bash
                 fi
            fi
            print_success "Fish uninstalled."
        else
            print_info "Skipping uninstallation."
        fi
    else
        print_info "Fish shell not detected. Skipping."
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            print_warning "DRY RUN MODE ENABLED - No changes will be made"
            ;;
        --help)
            echo "Usage: ./install.sh [--dry-run]"
            exit 0
            ;;
    esac
done

# Start
check_system
setup_aur_helper
install_selected_packages
backup_and_link_configs
post_install_steps
uninstall_fish

echo -e "\n${GREEN}All tasks completed!${NC}"
echo -e "${CYAN}You may need to logout or restart for all changes to take effect.${NC}"
