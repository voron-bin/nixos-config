{ pkgs, ... }: {

	environment.systemPackages = with pkgs; [
		# purely an option if I want a hostname to have different packages than is standard
		xf86-video-intel
		bluez
	];

	hardware.graphics = {
		enable = true;
		extraPackages = [ pkgs.intel-media-driver ];
	};
}
