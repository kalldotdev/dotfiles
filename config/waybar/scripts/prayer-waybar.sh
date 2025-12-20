#!/bin/bash

# Log file for debugging
LOG="/tmp/waybar_prayer.log"

# 1. Run go-pray and strip ANSI color codes
# The 'sed' command removes invisible color characters
RAW_OUTPUT=$(go-pray calendar | sed 's/\x1b\[[0-9;]*m//g')

# Debug: Write raw output to log to see what the script actually sees
echo "--- Raw Output ---" >"$LOG"
echo "$RAW_OUTPUT" >>"$LOG"

# 2. Extract times
# We search for the pattern "HH:MM" (e.g., 04:12 or 19:30)
# We default to "00:00" if empty to prevent JSON crashes
FAJR=$(echo "$RAW_OUTPUT" | grep -i "Fajr" | grep -o '[0-9]\{2\}:[0-9]\{2\}' | head -n1)
DHUHR=$(echo "$RAW_OUTPUT" | grep -i "Dhuhr" | grep -o '[0-9]\{2\}:[0-9]\{2\}' | head -n1)
ASR=$(echo "$RAW_OUTPUT" | grep -i "Asr" | grep -o '[0-9]\{2\}:[0-9]\{2\}' | head -n1)
MAGHRIB=$(echo "$RAW_OUTPUT" | grep -i "Maghrib" | grep -o '[0-9]\{2\}:[0-9]\{2\}' | head -n1)
ISHA=$(echo "$RAW_OUTPUT" | grep -i "Isha" | grep -o '[0-9]\{2\}:[0-9]\{2\}' | head -n1)

# Debug: Log parsed times
echo "--- Parsed ---" >>"$LOG"
echo "Fajr: $FAJR" >>"$LOG"

# 3. Convert Time Function
to_mins() {
  # If empty, return large number to avoid triggering
  if [ -z "$1" ]; then
    echo 9999
    return
  fi
  IFS=: read -r h m <<<"$1"
  # Remove leading zeros (e.g., 04 -> 4) to avoid octal error
  h=${h#0}
  m=${m#0}
  echo $((h * 60 + m))
}

CURRENT_HM=$(date +%H:%M)
CURRENT_MINS=$(to_mins "$CURRENT_HM")

# 4. Logic: Find Next Prayer
# We handle empty vars by checking syntax length
if [ -z "$FAJR" ]; then
  echo "{\"text\": \"Parse Error\", \"tooltip\": \"Check /tmp/waybar_prayer.log\", \"class\": \"offline\"}"
  exit 1
fi

if [ "$CURRENT_MINS" -lt $(to_mins "$FAJR") ]; then
  NEXT="Fajr"
  TIME="$FAJR"
elif [ "$CURRENT_MINS" -lt $(to_mins "$DHUHR") ]; then
  NEXT="Dhuhr"
  TIME="$DHUHR"
elif [ "$CURRENT_MINS" -lt $(to_mins "$ASR") ]; then
  NEXT="Asr"
  TIME="$ASR"
elif [ "$CURRENT_MINS" -lt $(to_mins "$MAGHRIB") ]; then
  NEXT="Maghrib"
  TIME="$MAGHRIB"
elif [ "$CURRENT_MINS" -lt $(to_mins "$ISHA") ]; then
  NEXT="Isha"
  TIME="$ISHA"
else
  NEXT="Fajr"
  TIME="$FAJR" # Tomorrow
fi

# 5. Output JSON
TOOLTIP="Gresik (go-pray)\n----------------\nFajr: $FAJR\nDhuhr: $DHUHR\nAsr: $ASR\nMaghrib: $MAGHRIB\nIsha: $ISHA"
echo "{\"text\": \"🕌 $NEXT $TIME\", \"tooltip\": \"$TOOLTIP\", \"class\": \"prayer\"}"
