#!/bin/sh
# Prints the backlight percentage whenever it changes.
# Exits immediately on machines without a backlight (the desktop).

d=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n 1)
[ -z "$d" ] && exit 0

max=$(cat "$d/max_brightness")
last=-1
while true; do
  cur=$(cat "$d/brightness")
  pct=$((cur * 100 / max))
  if [ "$pct" != "$last" ]; then
    echo "$pct"
    last=$pct
  fi
  sleep 0.3
done
