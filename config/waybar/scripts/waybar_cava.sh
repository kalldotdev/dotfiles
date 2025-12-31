#!/bin/bash
# script to read from a Cava config and output to Waybar

bar=" ▂▃▄▅▆▇█"
dict="s/;//g;"

# Calculate length of bar string
bar_len=${#bar}

# create dictionary to replace char with bar
for ((i=0; i<$bar_len; i++)); do
    dict="${dict}s/$i/${bar:$i:1}/g;"
done

# kill cava if already running
pkill -f "cava -p ~/.config/cava/waybar_config"

# read from pipe
cava -p ~/.config/cava/waybar_config | sed -u "$dict"
