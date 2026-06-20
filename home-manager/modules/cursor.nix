{ pkgs, ... }:
let
  kdeClassicCursors = pkgs.stdenv.mkDerivation {
    pname = "kde-classic-remastered-cursors";
    version = "1.0";
    src = ../assets/cursor/KDE-classic.tar.gz;
    installPhase = ''
      mkdir -p $out/share/icons
      tar -xzf $src -C $out/share/icons
    '';
  };

in {
  home.pointerCursor = {
    gtk.enable = true;
    package = kdeClassicCursors;
    name = "KDE-classic";  # confirm exact internal folder name after extraction
    size = 24;
  };
}
