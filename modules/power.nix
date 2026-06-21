{
	powerManagement.enable = true;

	# lid switch starts suspend then hibernate
	services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
	services.logind.settings.Login.HandleLidSwitchExternalPower = "suspend-then-hibernate";

	# hibernate on power button pressed
	services.logind.settings.Login.HandlePowerKey = "hibernate";
	services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

	# suspend first
	boot.kernelParams = ["mem_sleep_default=deep"];

	# define time delay for hibernation
	systemd.sleep.settings.Sleep = {
		HibernateDelaySec = "30m";
		SuspendState = "mem";
	};
}
