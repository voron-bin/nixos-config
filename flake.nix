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
				{ hostname = "nixputer"; stateVersion = "26.05"; gpuDriver = "discrete"; }
				# can uncomment when I am ready for the laptop
				# { hostname = "thinkputer"; stateVersion = "26.05"; }
			];

			makeSystem = host: nixpkgs.lib.nixosSystem {
				system = system;
				specialArgs = {
					inherit inputs user;
					inherit (host) hostname stateVersion;
					host = host;
				};

				modules = [
					./hosts/${host.hostname}/configuration.nix
				];
			};

		in {
			# basically creates a new entry based on the listed hosts above using foldl
			nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
				configs // {
					"${host.hostname}" = makeSystem host;
				}) {} hosts;

			homeConfigurations.${user} = inputs.home-manager.lib.homeManagerConfiguration {
				pkgs = nixpkgs.legacyPackages.${system};
				extraSpecialArgs = {
					inherit inputs homeStateVersion user;
				};

				modules = [
					./home-manager/home.nix
				];
			};
		};
	}
