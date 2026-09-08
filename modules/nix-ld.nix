{ config, pkgs, ... }:

{
programs.nix-ld = {
  enable = true;
  libraries = with pkgs; [
    stdenv.cc.cc   # gcc runtime libs
    zlib
    openssl
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    libGL
    pulseaudio
    udev
    fontconfig
    freetype
    dbus
  ];
};
}
