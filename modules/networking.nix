services.mullvad-vpn.enable = true;

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
