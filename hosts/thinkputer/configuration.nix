{ pkgs, stateVersion, hostname, ... }:

{
	# import configurations and other nix files
	imports = [
		./hardware-configuration.nix
		./local-packages.nix
		../../modules
	];

	# import packages from the stated file
	environment.systemPackages = [ pkgs.home-manager ];

	# grab the hostname from the file
	networking.hostName = hostname;

	system.stateVersion = stateVersion;

	nixpkgs.config.allowUnfree = true;

	services.thermald.enable = true;

	services.upower.enable = true;

	services.tlp = {
		enable = true;
		pd.enable = true;
		settings = {
			CPU_SCALING_GOVERNOR_ON_AC = "performance";
			CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

			CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
			CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

			CPU_MIN_PERF_ON_AC = 0;
			CPU_MAX_PERF_ON_AC = 100;

			CPU_MIN_PERF_ON_BAT = 0;
			CPU_MAX_PERF_ON_BAT = 20;

			# Optional helps save long term battery health
			START_CHARGE_THRESH_BAT0 = 60; # 40 and below it starts to charge
			STOP_CHARGE_THRESH_BAT0 = 80;  # 80 and above it stops charging
		};
	};


}
