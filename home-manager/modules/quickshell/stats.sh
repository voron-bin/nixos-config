#!/bin/sh
# Prints one line every 2 seconds:
#   cpu% memUsedGiB memTotalGiB cpuTemp gpuTemp battery charging vpn net
# -1 means "not present on this machine" (no amdgpu, no battery).
# Read by shell.qml via Quickshell.Io.Process.

# A systemd user service starts with a minimal PATH; add the NixOS locations
# so nmcli and mullvad are found there too.
PATH="$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin"

# Find a hwmon device by name and print its temp1_input in degrees C (-1 if not found).
# k10temp temp1 = Tctl, coretemp temp1 = Package id 0, amdgpu temp1 = edge,
# the same sensors your ashell modules read through `sensors`.
hw() {
  for d in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$d/name" 2>/dev/null)" = "$1" ] || continue
    t=$(cat "$d/temp1_input" 2>/dev/null) || continue
    echo $((t / 1000))
    return
  done
  echo -1
}

prev_total=0
prev_idle=0

while true; do
  # CPU usage from the delta of /proc/stat between iterations
  read -r _ u n s i io irq sirq st _ < /proc/stat
  idle=$((i + io))
  total=$((u + n + s + i + io + irq + sirq + st))
  dt=$((total - prev_total))
  di=$((idle - prev_idle))
  if [ "$dt" -gt 0 ]; then
    cpu=$(((100 * (dt - di)) / dt))
  else
    cpu=0
  fi
  prev_total=$total
  prev_idle=$idle

  # Memory: used and total in GiB
  mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d %d", (t-a)/1048576+0.5, t/1048576+0.5}' /proc/meminfo)

  # Temperatures: AMD CPU (k10temp) on the desktop, Intel (coretemp) on the laptop
  cpu_t=$(hw k10temp)
  [ "$cpu_t" = -1 ] && cpu_t=$(hw coretemp)
  gpu_t=$(hw amdgpu)

  # Battery (laptop only): percent, charging flag, power draw, time left, health
  bat=-1
  chg=0
  w10=-1      # power draw in tenths of a watt
  mins=-1     # minutes to empty (or to full while charging)
  health=-1   # full capacity vs design capacity, percent
  for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] || continue
    bat=$(cat "$b/capacity")
    st=$(cat "$b/status" 2>/dev/null)
    [ "$st" = "Charging" ] && chg=1

    # values in microwatt-hours / microwatts (some batteries report charge + voltage instead)
    now=""; full=""; design=""; pw=""
    if [ -r "$b/energy_now" ]; then
      now=$(cat "$b/energy_now")
      full=$(cat "$b/energy_full" 2>/dev/null)
      design=$(cat "$b/energy_full_design" 2>/dev/null)
      pw=$(cat "$b/power_now" 2>/dev/null)
    elif [ -r "$b/charge_now" ] && [ -r "$b/voltage_now" ]; then
      v=$(cat "$b/voltage_now")
      now=$(( $(cat "$b/charge_now") * v / 1000000 ))
      full=$(( $(cat "$b/charge_full" 2>/dev/null || echo 0) * v / 1000000 ))
      design=$(( $(cat "$b/charge_full_design" 2>/dev/null || echo 0) * v / 1000000 ))
      pw=$(( $(cat "$b/current_now" 2>/dev/null || echo 0) * v / 1000000 ))
    fi
    pw=${pw#-}   # some drivers report discharge as negative
    if [ -n "$pw" ] && [ "$pw" -gt 0 ] 2>/dev/null; then
      w10=$((pw / 100000))
      if [ "$st" = "Discharging" ]; then
        mins=$((now * 60 / pw))
      elif [ "$st" = "Charging" ] && [ -n "$full" ]; then
        mins=$(((full - now) * 60 / pw))
      fi
    fi
    if [ -n "$design" ] && [ "$design" -gt 0 ] 2>/dev/null && [ -n "$full" ]; then
      health=$((full * 100 / design))
    fi
    break
  done

  # screen recording in progress? (toggled with SUPER + R)
  if pgrep -x wf-recorder >/dev/null 2>&1; then rec=1; else rec=0; fi

  # VPN + network type, same nmcli logic as your RuVpn module
  nm=$(nmcli -t -f TYPE,STATE connection show --active 2>/dev/null)
  if echo "$nm" | grep -Eq '^(vpn|wireguard|tun|tap):activated'; then
    vpn=on
  else
    vpn=off
  fi
  # Mullvad runs its own tunnel that NetworkManager doesn't see, so ask the daemon too
  if [ "$vpn" = off ] && [ "$(mullvad status 2>/dev/null | head -n 1 | cut -d' ' -f1)" = "Connected" ]; then
    vpn=on
  fi
  case "$nm" in
    *wireless:activated* | *wifi:activated*) net=wifi ;;
    *ethernet:activated*) net=ethernet ;;
    *) net=none ;;
  esac

  echo "$cpu $mem $cpu_t $gpu_t $bat $chg $vpn $net $rec $w10 $mins $health"
  sleep 2
done
