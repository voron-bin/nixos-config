{
	description = "Voronezh NixOS Configuration";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # specifies the unstable channel for updating packages

		# adding home manager
		home-manager = {
			# this url is for the master branch (default)
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nixvim = {
			url = "github:nix-community/nixvim";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# adding disko for disk formatting
		disko = {
			url = "github:nix-community/disko";
			inputs.nixpkgs.follows = "nixpkgs";
		};

	};

	outputs = { self, nixpkgs, ... }@inputs:

		let
			# define sys arch for reuse
			system = "x86_64-linux";
			# define home-manager state for reuse
			homeStateVersion = "26.05";
			# define user for reuse
			user = "boris";
			# define hostnames for ease of use
			hosts = [
				{ hostname = "nixputer"; stateVersion = "26.05"; gpuDriver = "discrete"; monitor = "3440x1440@165"; uuid = "d8b9936a-4327-45b8-b95c-92a53d783d14"; resumeOffset = "533760"; }
				{ hostname = "thinkputer"; stateVersion = "26.05"; gpuDriver = "integrated"; monitor = "1920x1080@60"; }
			];

			makeSystem = host: nixpkgs.lib.nixosSystem {
				system = system;
				specialArgs = {
					inherit inputs user;
					inherit (host) hostname stateVersion gpuDriver;
					host = host;
					# passing variables needed for hibernation and swap
					uuid = host.uuid or "";
					resumeOffset = host.resumeOffset or "";
				};

				modules = [
					./hosts/${host.hostname}/configuration.nix
					./hosts/${host.hostname}/desktop-disko.nix
					inputs.disko.nixosModules.disko
				];
			};

		in {
			# basically creates a new entry based on the listed hosts above using foldl
			nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
				configs // {
					"${host.hostname}" = makeSystem host;
				}) {} hosts;

			# Generate unique home configurations dynamically per host
			homeConfigurations = nixpkgs.lib.foldl' (configs: host:
				configs // {
					"${user}@${host.hostname}" = inputs.home-manager.lib.homeManagerConfiguration {
						pkgs = nixpkgs.legacyPackages.${system};
						extraSpecialArgs = {
							inherit inputs homeStateVersion user;
							monitor = host.monitor or "";
						};
					modules = [
						./home-manager/home.nix
					];
				};
			}) {} hosts;
		};
	}
