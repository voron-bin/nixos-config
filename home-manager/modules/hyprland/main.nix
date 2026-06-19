{
	wayland.windowManager.hyprland = {
		enable = true;
		systemd.enable = true;
		# stating the old .conf style of config file for compat
		configType = "hyprlang";
		settings = {
			env = [
        			# env variable for apps launched while using hyprland
				# acts to improve performance of apps typically not made for wayland
        			"NIXOS_OZONE_WL,1"
        			"XDG_CURRENT_DESKTOP,Hyprland"
        			"XDG_SESSION_TYPE,wayland"
        			"XDG_SESSION_DESKTOP,Hyprland"
        			"QT_QPA_PLATFORM,wayland"
        			"XDG_SCREENSHOTS_DIR,$HOME/screens"
      			];

			monitor = ",3440x1440@165,auto,auto";
			"$mainMod" = "SUPER";
			"$terminal" = "kitty";
			"$fileManager" = "$terminal -e sh -c 'ranger'";
			"$menu" = "rofi -show drun";
			"$browser" = "mullvad-browser";

			exec-once = [
			# may not need this in actuality, but will want to consider getting this fixed in case I need it in the future
			# "/usr/lib/hyprpolkitagent/hyprpolkitagent"
			
			# starting wallpaper daemon and ashell
			"awww-daemon & ashell"
			
			# running a short script to find a random wallpaper
			# may not work under the nix directory structure
			"sleep 1 && awww img '$(find ~/Wallpapers -type f \( -name '*.jpg' -o -name '*.png' \) | shuf -n 1)' --transition-type none"

			"[workspace special:ВСП silent] mullvad-vpn"
			"[workspace 1 silent] $terminal"
			"[workspace 2 silent] $browser"
			"[workspace 10 silent] spotify-launcher"
			"nextcloud --background"

			# starting notification daemon
			"mako"
			];

			general = {
				border_size = 1;
				"col.active_border" = "rgb(A84826)";
				"col.inactive_border" = "rgb(3D3833)";
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
				bezier = "linear, 0.0, 0.0, 1.0, 1.0";
				animation = [
					"windows, 1, 3, linear"
					"fade, 1, 4, linear"
					"workspaces, 1, 3, linear"
				];
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
}
