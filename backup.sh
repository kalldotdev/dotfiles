#!/bin/bash

# Define paths
SOURCE_DIR="$HOME/.config"
DEST_DIR="$HOME/dotfiles/config"
ROOT_DIR="$HOME/dotfiles"

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Backup...${NC}"

# list of folders to backup from ~/.config/
folders=(
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

# 1. Backup Config Folders
for folder in "${folders[@]}"; do
    if [ -d "$SOURCE_DIR/$folder" ]; then
        echo "Backing up $folder..."
        # rm -rf ensures we delete old backup files so we have a clean 1:1 copy
        rm -rf "$DEST_DIR/$folder"
        cp -r "$SOURCE_DIR/$folder" "$DEST_DIR/"
    else
        echo "Skipping $folder (Not found)"
    fi
done

# 2. Backup Shell Configs (Bash/Zsh)
if [ -f "$HOME/.bashrc" ]; then
    echo "Backing up .bashrc..."
    cp "$HOME/.bashrc" "$ROOT_DIR/"
fi

if [ -f "$HOME/.zshrc" ]; then
    echo "Backing up .zshrc..."
    cp "$HOME/.zshrc" "$ROOT_DIR/"
fi

# 3. Git Status (Optional)
echo -e "${GREEN}Backup Complete!${NC}"
echo "Run the following to push to GitHub:"
echo "cd ~/dotfiles"
echo "git add ."
echo "git commit -m 'Update config'"
echo "git push"
