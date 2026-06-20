# modules-system/zswap.nix
{ config, lib, ... }: {

  # Enable ZSwap compression layer
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=20"
    "zswap.accept_threads=4"    # Parallel compression for better performance
    "zswap.same_filled_pages_enabled=1"  # Deduplicate zero-filled pages
    "resume_offset=533760" 
  ];

  # Hibernation resume device
  # IMPORTANT: After installation, verify the correct device with 'lsblk -f'
  # and update this path if needed. Using label is safer than raw device paths.

  # make sure that this is disabled when installing a new device as the offset may change and this is dictated by the disk
  powerManagement.enable = true;
  boot.resumeDevice = "/dev/disk/by-uuid/d8b9936a-4327-45b8-b95c-92a53d783d14";

  # Swap device declaration (disko creates the file, this tells the kernel to use it)
  swapDevices = [
    { device = "/.swapvol/swapfile"; }
  ];
}
