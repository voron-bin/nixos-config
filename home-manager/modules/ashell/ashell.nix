{ configs, pkgs, ...}:

{
	# symlink to the config file
	xdg.configfile."ashell/config.toml".source = ./config.toml;

	home.packages = with pkgs; [
		# declaring packages that are needed for ashell
		ashell
		procps
		lm_sensors
		networkmanager
		inotify-tools
	];
}
