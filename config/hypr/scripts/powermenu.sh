#!/bin/bash

# Options
lock="  Lock"
logout="  Logout"
suspend="  Suspend"
reboot="  Reboot"
shutdown="  Shutdown"

# Wofi Command
# We use a custom style name "powermenu" so it doesn't mess up your normal launcher look
wofi_command="wofi --show dmenu --conf $HOME/.config/wofi/config.power --style $HOME/.config/wofi/style.power.css"

# Options to pass to wofi
options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

selected=$(echo -e "$options" | $wofi_command)

case $selected in
"$lock")
  hyprlock
  ;;
"$logout")
  loginctl terminate-user $USER
  ;;
"$suspend")
  systemctl suspend
  ;;
"$reboot")
  systemctl reboot
  ;;
"$shutdown")
  systemctl poweroff
  ;;
esac
