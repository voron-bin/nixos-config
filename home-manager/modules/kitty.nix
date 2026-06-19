{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "PxPlus IBM VGA 8x14";
      size = 16.0;
    };

    settings = {
      # Base Application Colors
      background = "#1c1917";
      foreground = "#d6cfc2";
      selection_background = "#a84826";
      selection_foreground = "#1c1917";

      # Black
      color0  = "#1c1917";
      color8  = "#3d3833";

      # Red
      color1  = "#a84826";
      color9  = "#c8302e";

      # Green
      color2  = "#7a8066";
      color10 = "#9ba285";

      # Yellow
      color3  = "#b89650";
      color11 = "#d4b070";

      # Blue
      color4  = "#6b7278";
      color12 = "#8a9199";

      # Magenta
      color5  = "#8b5e4a";
      color13 = "#ab7866";

      # Cyan
      color6  = "#8b9289";
      color14 = "#aab0a6";

      # White
      color7  = "#d6cfc2";
      color15 = "#e8e1d4";
    };
  };
}
