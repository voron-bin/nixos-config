{ pkgs, lib, config, monitor, scale,  ... }:

let
  mk = lib.generators.mkLuaInline;

  # Complex shell logic lives in a script so no quoting passes through the Lua generator
  wallpaper = pkgs.writeShellScript "random-wallpaper" ''
    sleep 1
    awww img "$(find ~/.wallpapers -type f \( -name '*.jpg' -o -name '*.png' \) | shuf -n 1)" --transition-type none
  '';
in
{
  # New random wallpaper every 3 hours (change both values below to taste).
  # The first one is still picked at login by the autostart block.
  systemd.user.services.random-wallpaper = {
    Unit.Description = "Pick a random wallpaper";
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaper}";
      Environment = [
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin"
      ];
    };
  };
  systemd.user.timers.random-wallpaper = {
    Unit.Description = "Change the wallpaper every few hours";
    Timer = {
      OnStartupSec = "3h";
      OnUnitActiveSec = "3h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    configType = "lua";

    settings = {
      # hl.env("NAME", "value") -- one call per list element, two args each
      env = [
        # env variables for apps launched while using hyprland
        # improves performance of apps typically not made for wayland
        { _args = [ "NIXOS_OZONE_WL" "1" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland" ]; }
        { _args = [ "XDG_SCREENSHOTS_DIR" "${config.home.homeDirectory}/screens" ]; }
        { _args = [ "XCURSOR_THEME" "KDE-classic" ]; }
        { _args = [ "XCURSOR_SIZE" "24" ]; }
      ];

      # hl.monitor({ ... })
      # mode = "<width>x<height>@<refresh>", e.g. "2560x1440@165"; "preferred" lets Hyprland choose
      monitor = {
        output = "";
        mode = monitor;
        position = "auto";
        scale = scale;
      };

      # Replaces exec-once
      on = {
        _args = [
          "hyprland.start"
          (mk ''
            function()
              -- wallpaper daemon (the bar is started by the quickshell systemd service)
              hl.exec_cmd("awww-daemon")
              -- random wallpaper (script defined in the let block above)
              hl.exec_cmd("${wallpaper}")

              hl.exec_cmd("mullvad-vpn", { workspace = "special:ВСП silent" })
              hl.exec_cmd("kitty", { workspace = "1 silent" })
              hl.exec_cmd("firefox", { workspace = "2 silent" })
              hl.exec_cmd("feishin", { workspace = "10 silent" })
              hl.exec_cmd("nextcloud --background")

              -- clipboard history (feeds the SUPER + C picker)
              hl.exec_cmd("wl-paste --type text --watch cliphist store")
              hl.exec_cmd("wl-paste --type image --watch cliphist store")

              -- (notifications are handled by the quickshell bar, so no mako here)
            end
          '')
        ];
      };

      # hl.curve(name, { ... }) -- top-level in Lua, not a config option
      curve = {
        _args = [
          "linear"
          (mk ''{ type = "bezier", points = { {0.0, 0.0}, {1.0, 1.0} } }'')
        ];
      };

      # hl.animation({ ... }) -- one call per element
      animation = [
        { leaf = "windows"; enabled = true; speed = 3; bezier = "linear"; }
        { leaf = "fade"; enabled = true; speed = 4; bezier = "linear"; }
        { leaf = "workspaces"; enabled = true; speed = 3; bezier = "linear"; }
      ];

      # hl.config({ ... }) -- all regular options live here
      config = {
        cursor = {
          enable_hyprcursor = false;
        };

        input = {
          accel_profile = "flat";
        };

        general = {
          border_size = 1;
          # dotted names nest in Lua: general.col.active_border
          col.active_border = "rgb(A84826)";
          col.inactive_border = "rgb(3D3833)";
          gaps_in = 4;
          gaps_out = 8;

          resize_on_border = false;
          allow_tearing = false;

          layout = "dwindle";
        };

        decoration = {
          rounding = 0;
          dim_inactive = true;
          dim_strength = 0.2;

          shadow = {
            enabled = false;
          };

          blur = {
            enabled = false;
          };
        };

        animations = {
          enabled = true;
        };

        dwindle = {
          preserve_split = true;
          smart_resizing = true;
          force_split = 2;
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };
      };
    };
  };
}
