{ lib, pkgs, ... }:

let
  mk = lib.generators.mkLuaInline;

  # SUPER + R: pick a region and start recording; press again to stop.
  # The bar shows ЗАП while it runs. Files go to ~/Videos.
  record = pkgs.writeShellScript "toggle-record" ''
    export PATH=${lib.makeBinPath [ pkgs.wf-recorder pkgs.slurp pkgs.procps pkgs.libnotify pkgs.coreutils ]}:$PATH
    if pgrep -x wf-recorder >/dev/null; then
      pkill -INT -x wf-recorder
      notify-send "Запись" "Сохранено в ~/Videos"
      exit 0
    fi
    mkdir -p "$HOME/Videos"
    region=$(slurp) || exit 0
    exec wf-recorder -g "$region" -f "$HOME/Videos/rec-$(date +%Y%m%d-%H%M%S).mp4"
  '';

  # Each helper returns one hl.bind(keys, dispatcher[, flags]) call
  bind = keys: action: { _args = [ keys (mk action) ]; };
  bindf = keys: action: flags: { _args = [ keys (mk action) flags ]; };

  # Dispatcher builders (return Lua source as a string)
  exec = cmd: ''hl.dsp.exec_cmd("${cmd}")'';
  focusDir = dir: ''hl.dsp.focus({ direction = "${dir}" })'';
  focusWs = ws: ''hl.dsp.focus({ workspace = ${ws} })'';
  moveToWs = ws: ''hl.dsp.window.move({ workspace = ${ws} })'';

  # SUPER + [1-9,0] to switch, SUPER + SHIFT + [1-9,0] to move (key 0 = workspace 10)
  workspaceBinds = lib.concatMap (n:
    let key = toString (lib.mod n 10); in [
      (bind "SUPER + ${key}" (focusWs (toString n)))
      (bind "SUPER + SHIFT + ${key}" (moveToWs (toString n)))
    ]) (lib.range 1 10);

  # volume/brightness keys: work on lockscreen and repeat when held
  fnKey = keys: cmd: bindf keys (exec cmd) { locked = true; repeating = true; };

  # media keys: work on lockscreen
  mediaKey = keys: cmd: bindf keys (exec cmd) { locked = true; };
in
{
  wayland.windowManager.hyprland.settings.bind =
    [
      # ---window control---
      # kill window
      (bind "SUPER + Q" "hl.dsp.window.close()")
      # toggle the floating status of the window
      (bind "SUPER + V" ''hl.dsp.window.float({ action = "toggle" })'')

      # Move focus with SUPER + arrow keys
      (bind "SUPER + left" (focusDir "left"))
      (bind "SUPER + right" (focusDir "right"))
      (bind "SUPER + up" (focusDir "up"))
      (bind "SUPER + down" (focusDir "down"))

      # special workspace
      (bind "SUPER + S" ''hl.dsp.workspace.toggle_special("ВСП")'')
      (bind "SUPER + SHIFT + S" (moveToWs ''"special:ВСП"''))

      # Scroll through existing workspaces with SUPER + scroll
      (bind "SUPER + mouse_down" (focusWs ''"e+1"''))
      (bind "SUPER + mouse_up" (focusWs ''"e-1"''))

      # ---binds for dwindle mode---
      # turns active window into a pseudo tile
      (bind "SUPER + P" "hl.dsp.window.pseudo()")
      # changes the split direction of the active window and active window pair
      (bind "SUPER + J" ''hl.dsp.layout("togglesplit")'')

      # ---program launching---
      (bind "SUPER + T" (exec "kitty"))
      (bind "SUPER + F" (exec "kitty -e sh -c 'ranger'"))
      # launch rofi (to launch another app)
      (bind "ALT + space" (exec "rofi -show drun"))
      (bind "SUPER + B" (exec "firefox"))
      # hyprshot to satty
      (bind "SUPER + K" (exec "hyprshot --mode region --raw | satty --filename -"))
      (bind "SUPER + SHIFT + K" (exec "hyprshot --mode window --raw | satty --filename -"))
      # screen recording toggle
      (bind "SUPER + R" (exec "${record}"))

      # ---session control---
      # log out of session (go back to display manager)
      (bind "SUPER + E" "hl.dsp.exit()")
      # lock screen
      (bind "SUPER + L" (exec "hyprlock"))

      # ---mouse binds---
      # Move/resize windows with SUPER + LMB/RMB and dragging
      (bindf "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
      (bindf "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })

      # ---laptop function keys---
      (fnKey "XF86AudioRaiseVolume" "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
      (fnKey "XF86AudioLowerVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
      (fnKey "XF86AudioMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
      (fnKey "XF86AudioMicMute" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
      (fnKey "XF86MonBrightnessUp" "brightnessctl -e4 -n2 set 5%+")
      (fnKey "XF86MonBrightnessDown" "brightnessctl -e4 -n2 set 5%-")

      # ---hardware media keys -- REQUIRES playerctl---
      (mediaKey "XF86AudioNext" "playerctl next")
      (mediaKey "XF86AudioPause" "playerctl play-pause")
      (mediaKey "XF86AudioPlay" "playerctl play-pause")
      (mediaKey "XF86AudioPrev" "playerctl previous")
    ]
    # ---workspaces---
    ++ workspaceBinds;
}
