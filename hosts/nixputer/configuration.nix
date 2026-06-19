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

}
