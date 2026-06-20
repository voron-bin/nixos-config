{ configs, pkgs, puterType, ...}:

{
	# symlink to the config file
	xdg.configFile."ashell/config.toml".source =
		if puterType == "laptop"
  		then ./laptop_config.toml
  		else ./config.toml;
	
	home.packages = with pkgs; [
		# declaring packages that are needed for ashell
		ashell
		procps
		lm_sensors
		networkmanager
		inotify-tools
	];
}
