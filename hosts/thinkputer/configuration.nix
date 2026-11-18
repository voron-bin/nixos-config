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

	services.fwupd.enable = true;

	services.throttled = {
	
	enable = true;
		extraConfig = ''
		    [GENERAL]
		    Enabled: True
		    Sysfs_Power_Path: /sys/class/power_supply/AC*/online
		    Autoreload: True

		    [BATTERY]
		    Update_Rate_s: 30
		    PL1_Tdp_W: 15
		    PL1_Duration_s: 28
		    PL2_Tdp_W: 25
		    PL2_Duration_S: 0.002
		    Trip_Temp_C: 85
		    cTDP: 0
		    Disable_BDPROCHOT: False

		    [AC]
		    Update_Rate_s: 5
		    PL1_Tdp_W: 25
		    PL1_Duration_s: 28
		    PL2_Tdp_W: 44
		    PL2_Duration_S: 0.002
		    Trip_Temp_C: 95
		    HWP_Mode: False
		    cTDP: 0
		    Disable_BDPROCHOT: False
		  '';
	};

	services.thermald.enable = false;

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
