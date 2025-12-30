#!/bin/bash

# Dotfiles Backup Script
# Backs up local configurations to dotfiles repo and pushes to Git

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
LOG_FILE="${SCRIPT_DIR}/backup.log"

# Dry run mode
DRY_RUN=false

# Check for flags
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --help)
            echo "Usage: ./backup.sh [OPTIONS]"
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

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] Would execute: $*${NC}"
    else
        "$@"
    fi
}

# ==============================================================================
# LOGIC
# ==============================================================================

backup_configs() {
    print_header "Backing up Configurations"
    
    local config_dirs=(
        "hypr"
        "waybar"
        "rofi"
        "wofi"
        "alacritty"
        "mako"
        "wlogout"
        "go-pray"
        "ghostty"
        "dunst"
    )

    for dir in "${config_dirs[@]}"; do
        if [ -d "$HOME/.config/$dir" ]; then
            print_info "Syncing $dir..."
            
            # Create dest if needed
            run_cmd mkdir -p "$SCRIPT_DIR/config/$dir"
            
            # Sync content (using rsync if available would be better, but cp is standard)
            # We empty directory first to ensure 1:1 sync (handling deletions)
            if [ "$DRY_RUN" = false ]; then
                rm -rf "$SCRIPT_DIR/config/$dir"/*
                cp -r "$HOME/.config/$dir/"* "$SCRIPT_DIR/config/$dir/"
            else
                 echo -e "${YELLOW}[DRY RUN] Would sync contents of ~/.config/$dir to $SCRIPT_DIR/config/$dir${NC}"
            fi
        else
            print_warning "$dir not found in ~/.config/"
        fi
    done
    
    # Backup Shell
    print_info "Syncing Shell Configs..."
    if [ -f "$HOME/.bashrc" ]; then
        run_cmd cp "$HOME/.bashrc" "$SCRIPT_DIR/"
    fi
    if [ -f "$HOME/.zshrc" ]; then
        run_cmd cp "$HOME/.zshrc" "$SCRIPT_DIR/"
    fi
    
    print_success "Local backup complete!"
}

git_commit_push() {
    print_header "Git Synchronization"
    
    # Check if inside git repo
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        print_error "Not a git repository."
        return
    fi
    
    # Check status
    if [ -z "$(git status --porcelain)" ]; then
        print_success "No changes to commit."
        return
    fi
    
    git status
    
    echo
    read -p "Do you want to commit and push these changes? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Git operations skipped."
        return
    fi
    
    read -p "Enter commit message (Default: 'Update dotfiles'): " commit_msg
    commit_msg=${commit_msg:-"Update dotfiles"}
    
    print_info "Staging all changes..."
    run_cmd git add .
    
    print_info "Committing..."
    run_cmd git commit -m "$commit_msg"
    
    print_info "Pushing to remote..."
    run_cmd git push
    
    print_success "Changes pushed successfully!"
}

# ==============================================================================
# MAIN
# ==============================================================================

touch "$LOG_FILE"
backup_configs
git_commit_push
