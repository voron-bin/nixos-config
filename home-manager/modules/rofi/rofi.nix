{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = ./voronezh.rasi;
    plugins = [ pkgs.rofi-calc ];

    # `terminal` and `extraConfig` were deprecated, everything lives in `settings` now
    settings = {
      terminal = "kitty";

      # modes, switch between them with Shift+Right / Ctrl+Tab
      modi = "drun,window,run";
      display-drun = "ПУСК";
      display-window = "ОКНА";
      display-run = "КОМАНДА";

      # application icons
      show-icons = true;
      icon-theme = "Tela-dark";
      drun-display-format = "{name}";

      # search
      matching = "fuzzy";
      sorting-method = "fzf";

      # hover highlights an entry (like the bar), click launches it
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
    };
  };

  # icon theme used by show-icons above
  home.packages = [ pkgs.tela-icon-theme ];
}
