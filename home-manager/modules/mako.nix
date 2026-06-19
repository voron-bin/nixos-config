{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    
    # Global defaults
    backgroundColor = "#1C1917";
    textColor = "#D6CFC2";
    borderColor = "#A84826";
    borderSize = 1;
    borderRadius = 0;
    defaultTimeout = 5000;
    ignoreTimeout = false;
    layer = "overlay";
    anchor = "top-right";
    margin = "8";
    padding = "10";
    maxIconSize = 32;
    font = "PxPlus IBM VGA 8x14 12";
    width = 360;
    height = 120;
    progressColor = "over #A84826";

    # Urgency, Category, and Grouping behaviors
    extraConfig = ''
      [urgency=low]
      border-color=#3D3833
      default-timeout=3000

      [urgency=normal]
      border-color=#A84826
      default-timeout=5000

      [urgency=critical]
      border-color=#C8302E
      default-timeout=0
      background-color=#262320

      [category=mpd]
      default-timeout=2000
      group-by=category

      [app-name=Firefox]
      group-by=summary

      [grouped]
      format=<b>%s</b>\n%b\n(+%h)
    '';
  };
}
