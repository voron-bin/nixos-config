#!/bin/sh
# Small actions for the control panel and dashboard.
#   ctl.sh status            -> "<wifi> <bluetooth> <power-profile>"
#   ctl.sh wifi|bt|vpn|profile   toggle / cycle
#   ctl.sh weather [city]    -> one line from wttr.in

# A systemd user service starts with a minimal PATH; add the NixOS locations.
PATH="$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin"

case "$1" in
  status)
    wifi=$(nmcli radio wifi 2>/dev/null)
    bt=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')
    prof=$(powerprofilesctl get 2>/dev/null)
    echo "${wifi:---} ${bt:---} ${prof:---}"
    ;;
  wifi)
    if [ "$(nmcli radio wifi)" = enabled ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
    ;;
  bt)
    if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
      bluetoothctl power off
    else
      bluetoothctl power on
    fi
    ;;
  vpn)
    if [ "$(mullvad status 2>/dev/null | head -n 1 | cut -d' ' -f1)" = Connected ]; then
      mullvad disconnect
    else
      mullvad connect
    fi
    ;;
  profile)
    case "$(powerprofilesctl get 2>/dev/null)" in
      power-saver) powerprofilesctl set balanced ;;
      balanced) powerprofilesctl set performance 2>/dev/null || powerprofilesctl set power-saver ;;
      *) powerprofilesctl set power-saver ;;
    esac
    ;;
  weather)
    # %t = temperature, %C = condition text
    curl -s --max-time 10 "https://wttr.in/$2?format=%t+%C&lang=ru"
    ;;
esac
