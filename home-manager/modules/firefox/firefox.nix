{ inputs, pkgs, ... }: {
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.system}; [
        ublock-origin
        floccus
        proton-pass
      ];
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;	
	"extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
	"layout.css.prefers-color-scheme.content-override" = 0;
      };
      extraConfig = builtins.readFile (pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js";
        sha256 = "sha256-5KszxpFImRdc9wNeDlei1/CKyIfY+VfxGZ5+Sbvn4z4=";
      });
      userChrome = builtins.readFile ./userChrome.css;
    };
  };
}
