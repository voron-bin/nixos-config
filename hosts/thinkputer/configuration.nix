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

	services.fwupd.enable = true;

	services.throttled.enable = false;

	systemd.services.rapl-mmio-pl1 = {
  
		description = "Set MMIO package power limit (PL1) based on AC state";
		serviceConfig.Type = "oneshot";
			script = ''
			f=/sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
			if [ "$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n1)" = "1" ]; then
				echo 25000000 > "$f"   # plugged in: 25 W
			else
				echo 15000000 > "$f"   # battery: 15 W
			fi

			'';
	};

	systemd.timers.rapl-mmio-pl1 = {
		wantedBy = [ "timers.target" ];
		timerConfig = {
		OnBootSec = "30s";
		OnUnitActiveSec = "1min";
		};
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
