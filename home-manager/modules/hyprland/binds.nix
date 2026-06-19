{
wayland.windowManager.hyprland.settings = {
	# keyb bindings
	bind = [
		# ---window control---
		# kill window
		"$mainMod, Q, killactive,"
		# toggle the floating status of the window
		"$mainMod, V, togglefloating,"

		# Move focus with mainMod + arrow keys
		"$mainMod, left, movefocus, l"
		"$mainMod, right, movefocus, r"
		"$mainMod, up, movefocus, u"
		"$mainMod, down, movefocus, d"

		# ---worspaces---
		# Switch workspaces with mainMod + [0-9]
		"$mainMod, 1, workspace, 1"
		"$mainMod, 2, workspace, 2"
		"$mainMod, 3, workspace, 3"
		"$mainMod, 4, workspace, 4"
		"$mainMod, 5, workspace, 5"
		"$mainMod, 6, workspace, 6"
		"$mainMod, 7, workspace, 7"
		"$mainMod, 8, workspace, 8"
		"$mainMod, 9, workspace, 9"
		"$mainMod, 0, workspace, 10"

		# Move active window to a workspace with mainMod + SHIFT + [0-9]
		"$mainMod SHIFT, 1, movetoworkspace, 1"
		"$mainMod SHIFT, 2, movetoworkspace, 2"
		"$mainMod SHIFT, 3, movetoworkspace, 3"
		"$mainMod SHIFT, 4, movetoworkspace, 4"
		"$mainMod SHIFT, 5, movetoworkspace, 5"
		"$mainMod SHIFT, 6, movetoworkspace, 6"
		"$mainMod SHIFT, 7, movetoworkspace, 7"
		"$mainMod SHIFT, 8, movetoworkspace, 8"
		"$mainMod SHIFT, 9, movetoworkspace, 9"
		"$mainMod SHIFT, 0, movetoworkspace, 10"

		# special workspace
		"$mainMod,       S, togglespecialworkspace, ВСП"
		"$mainMod SHIFT, S, movetoworkspace, special:ВСП"

		# Scroll through existing workspaces with mainMod + scroll
		"$mainMod, mouse_down, workspace, e+1"
		"$mainMod, mouse_up, workspace, e-1"
		
		# ---binds for dwindle mode---
		# turns active window int a pseudo tile
		"$mainMod, P, pseudo,"
		# changes the split direction of the active window and active window pair
		"$mainMod, J, layoutmsg, togglesplit"

		# ---program launching---
		# launch terminal
		"$mainMod, T, exec, $terminal"
		# launch file manager
		"$mainMod, F, exec, $fileManager"
		# launch rofi (to launch another app)
		"alt, space, exec, $menu"
		# launch browser
		"$mainMod, B, exec, $browser"
		
		# ---session control---
		# log out of session (go back to display manager)
		"$mainMod, E, exit,"
		# lock screen
		"$mainMod, L, exec, hyprlock"
	];
	
	# mouse bindings
	bindm = [
		# Move/resize windows with mainMod + LMB/RMB and dragging
		"$mainMod, mouse:272, movewindow"
		"$mainMod, mouse:273, resizewindow"
	];

	# laptop function key bindings
	bindel = [
		",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
		",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
		",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
		",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
		",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
		",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
	];

	# hardware keys for media controls -- REQUIRES playerctl --
	bindl = [
		", XF86AudioNext, exec, playerctl next"
		", XF86AudioPause, exec, playerctl play-pause"
		", XF86AudioPlay, exec, playerctl play-pause"
		", XF86AudioPrev, exec, playerctl previous"
	];
};
}
