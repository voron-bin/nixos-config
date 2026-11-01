{ pkgs, ... }:

{
  home.packages = with pkgs; [
    quickshell
    # used by stats.sh, brightness.sh and ctl.sh
    procps
    lm_sensors
    networkmanager
    brightnessctl
    curl
    # media tooling
    playerctl
  ];

  # Own systemd user service, so it doesn't depend on home-manager's
  # programs.quickshell option names. Runs the config straight from the
  # folder this file is in (shell.qml and the helper scripts sit beside it).
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell bar";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell -p ${./.}";
      # so hyprctl, rofi, systemctl, nmcli etc. are found from inside the shell
      Environment = [
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
