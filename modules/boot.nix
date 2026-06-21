{ host, ... }: {

  boot.loader.systemd-boot.enable = false;  # must be explicit, not just removed
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;
  boot.loader.grub = {
    enable = true;
    device = "nodev";  # correct for UEFI installs — grub doesn't need a raw disk target here
    efiSupport = true;
    useOSProber = true;  # the actual feature you want — auto-detects Windows instead of manual entries
    extraEntries = ''
  	menuentry "UEFI Firmware Settings" {
		fwsetup
	}
    '';
    default = "saved";
    extraConfig = ''
        GRUB_SAVEDEFAULT=true
    '';

  };

}
