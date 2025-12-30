#!/bin/bash

# Apply Dotfiles Script
# Interactive configurator for existing setups

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
LOG_FILE="${SCRIPT_DIR}/apply.log"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# Dry run mode (can be set via --dry-run)
DRY_RUN=false

# Check for flags
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --help)
            echo "Usage: ./apply.sh [OPTIONS]"
            echo "Options:"
            echo "  --dry-run    Simulate actions without making changes"
            echo "  --help       Show this help message"
            exit 0
            ;;
    esac
done

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
        "$@"
    fi
}

# ==============================================================================
# MENU SYSTEM
# ==============================================================================

# Checkbox menu function
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
                     color="${GREEN}"
                fi
            fi
            
            echo -e "${color}${cursor} [${checked}] ${options[$i]} ${NC}- ${descs[$i]}"
        done
        
        if ! IFS= read -rsn1 key 2>/dev/null; then
            break
        fi
        
        if [[ $key == "" || $key == $'\n' ]]; then
            break
        elif [[ $key == " " ]]; then
            if [ "${statuses[$current]}" = true ]; then
                statuses[$current]=false
            else
                statuses[$current]=true
            fi
        elif [[ $key == $'\x1b' ]]; then
            if read -rsn2 -t 0.1 key 2>/dev/null; then
                if [[ $key == "[A" || $key == "OA" ]]; then
                    current=$((current-1))
                    [ $current -lt 0 ] && current=$((count-1))
                elif [[ $key == "[B" || $key == "OB" ]]; then
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

apply_config() {
    local configs_to_apply=()
    
    # Dynamic list of config directories
    local config_dirs=()
    local dir_descs=()
    
    for dir in "$SCRIPT_DIR/config/"*/; do
        dir=${dir%*/}
        dirname=${dir##*/}
        config_dirs+=("$dirname")
        dir_descs+=("Apply configuration for $dirname")
    done
    
    # Add Shells
    config_dirs+=("shell")
    dir_descs+=("Apply .bashrc details")
    
    # Prepare menu args
    local menu_args=()
    for ((i=0; i<${#config_dirs[@]}; i++)); do
        menu_args+=("${config_dirs[$i]}" "${dir_descs[$i]}")
    done
    
    MENU_DEFAULT_STATE=true
    checkbox_menu "Select Configurations to Apply" "${menu_args[@]}"
    
    for idx in "${SELECTED_INDICES[@]}"; do
        configs_to_apply+=("${config_dirs[$idx]}")
    done
    
    if [ ${#configs_to_apply[@]} -eq 0 ]; then
        print_warning "No configurations selected."
        exit 0
    fi
    
    echo -e "\n${BLUE}Selected Configurations:${NC}"
    for cfg in "${configs_to_apply[@]}"; do
        echo -e " - $cfg"
    done
    
    echo
    read -p "Proceed with application? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Application cancelled."
        exit 0
    fi
    
    # Setup Backup
    if [ "$DRY_RUN" = false ]; then
        run_cmd mkdir -p "$BACKUP_DIR"
    fi
    print_info "Backup directory: $BACKUP_DIR"
    
    for cfg in "${configs_to_apply[@]}"; do
        if [ "$cfg" == "shell" ]; then
            print_info "Backing up .bashrc..."
            if [ -f "$HOME/.bashrc" ]; then
                run_cmd cp "$HOME/.bashrc" "$BACKUP_DIR/"
            fi
            
            print_info "Applying .bashrc..."
            if [ -f "$SCRIPT_DIR/.bashrc" ]; then
                run_cmd cp "$SCRIPT_DIR/.bashrc" "$HOME/.bashrc"
            fi
            if [ -f "$SCRIPT_DIR/config/hypr/scripts/powermenu.sh" ]; then
                 run_cmd chmod +x "$SCRIPT_DIR/config/hypr/scripts/"*.sh 2>/dev/null || true
            fi
             if [ -f "$SCRIPT_DIR/config/waybar/scripts/prayer_times.sh" ]; then
                 run_cmd chmod +x "$SCRIPT_DIR/config/waybar/scripts/"*.sh 2>/dev/null || true
            fi

        else
            print_info "Backing up $cfg..."
            if [ -d "$HOME/.config/$cfg" ]; then
                run_cmd cp -r "$HOME/.config/$cfg" "$BACKUP_DIR/"
            fi
            
            print_info "Installing $cfg config..."
            run_cmd mkdir -p "$HOME/.config/$cfg"
            run_cmd cp -r "$SCRIPT_DIR/config/$cfg/"* "$HOME/.config/$cfg/"
        fi
    done
    
    print_success "Configurations applied successfully."
}

# ==============================================================================
# MAIN
# ==============================================================================

print_header "Dotfiles Configuration Applicator"
touch "$LOG_FILE"

apply_config

echo -e "\n${BLUE}To reload:${NC}"
echo -e "  • Hyprland: ${YELLOW}hyprctl reload${NC}"
echo -e "  • Waybar:   ${YELLOW}pkill waybar; waybar &${NC}"
echo -e "  • Shell:    ${YELLOW}source ~/.bashrc${NC}\n"
