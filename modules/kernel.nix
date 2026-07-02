# modules-system/kernel.nix
{ host, pkgs, ... }: {
  boot.kernelPackages = 
    if host.gpuDriver == "discrete" then 
      pkgs.linuxPackages_zen    # Desktop: Gaming kernel
    else 
      pkgs.linuxPackages;       # Laptop: Default kernel
}
