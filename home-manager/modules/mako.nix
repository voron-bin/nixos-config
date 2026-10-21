{ config, pkgs, ... }:

{
  services.mako = {
  enable = true;

  settings = {
    # Global defaults
    background-color = "#1C1917";
    text-color = "#D6CFC2";
    border-color = "#A84826";
    border-size = 1;
    border-radius = 0;
    default-timeout = 5000;
    ignore-timeout = false;
    layer = "overlay";
    anchor = "top-right";
    margin = "8";
    padding = "10";
    max-icon-size = 32;
    font = "PxPlus IBM VGA 8x14 12";
    width = 360;
    height = 120;
    progress-color = "over #A84826";

    # Urgency, Category, and Grouping behaviors
    "urgency=low" = {
      border-color = "#3D3833";
      default-timeout = 3000;
    };

    "urgency=normal" = {
      border-color = "#A84826";
      default-timeout = 5000;
    };

    "urgency=critical" = {
      border-color = "#C8302E";
      default-timeout = 0;
      background-color = "#262320";
    };

    "category=mpd" = {
      default-timeout = 2000;
      group-by = "category";
    };

    "app-name=Firefox" = {
      group-by = "summary";
    };

    grouped = {
      format = "<b>%s</b>\\n%b\\n(+%h)";
    };
  };
};
}
