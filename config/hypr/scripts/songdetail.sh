#!/bin/bash
# Get the song title and artist
SONG=$(playerctl metadata --format '{{title}} - {{artist}}' 2>/dev/null)

# If the song is empty (nothing playing), show nothing or a custom message
if [ -z "$SONG" ]; then
  echo "No Media Playing"
else
  echo "$SONG"
fi
