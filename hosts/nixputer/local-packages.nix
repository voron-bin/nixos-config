{ pkgs, ... }: {

	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true;
		dedicatedServer.openFirewall = true;
	};

	environment.systemPackages = with pkgs; [
		# purely an option if I want a hostname to have different packages than is standard
		steam	
	];
}
