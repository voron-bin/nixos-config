{ pkgs, ...}: {
	networking.networkmanager.enable = true;

	networking.enableIPv6 = true;
	
	services.mullvad-vpn.enable = true;
	
	services.mullvad-vpn.gui.enable = true;

	networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

	services.resolved = {
		enable = true;
		domains = [ "~." ];
		fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
		settings.Resolve = {	
			DNSSEC = "allow-downgrade";
			DNSOverTLS = "opportunistic";
  		};
	};
	
	services.avahi = {
		enable = true;
		nssmdns4 = true;
		openFirewall = true;
	};

	services.printing = {
		enable = true;
		drivers = with pkgs; [
			cups-filters
			cups-browsed
		];
	};
}
