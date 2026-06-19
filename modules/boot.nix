{ host, ... }: {

	# using systemd-boot
	boot.loader.systemd-boot = {
		enable = true;
		consoleMode = "max";
		editor = false;


	# defining windows entry
	extraEntries = {
		"windows.conf" = ''
				title Windows 11
				efi /EFI/Microsoft/Boot/bootmgfw.efi
				sort-key z_windows
			'';
		};
	};	

	boot.loader.efi.canTouchEfiVariables = true;
}
