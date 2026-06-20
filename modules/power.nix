{
	powerManagement.enable = true;

	services.power-profiles-daemon.enable = true;
	# lid switch starts suspend then hibernate
	services.logind.settings.Login.LidSwitch = "suspend-then-hibernate";
	# hibernate on power button pressed
	services.logind.settings.Login.PowerKey = "hibernate";
	services.logind.settings.Login.PowerKeyLongPress = "poweroff";

	# suspend first
	boot.kernelParams = ["mem_sleep_default=deep"];

	# define time delay for hibernation
	systemd.sleep.settings.Sleep = {
		HibernateDelaySec = "1m";
		SuspendState = "mem";
	};
}
