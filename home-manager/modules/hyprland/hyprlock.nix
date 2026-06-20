# modules-user/hyprlock.nix
{ pkgs, ... }:

let
  # Define your Voronezh Palette once here
  palette = {
    base_dark     = "rgba(1C1917FF)";
    surface       = "rgba(262320FF)";
    border_muted  = "rgba(3D3833FF)";
    text_primary  = "rgba(D6CFC2FF)";
    text_muted    = "rgba(7A7568FF)";
    rust          = "rgba(A84826FF)";
    warning_red   = "rgba(C8302EFF)";
    ochre         = "rgba(B89650FF)"; # Added for check_color
  };
in {

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
        disable_loading_bar = true;
      };

      background = [
        { color = palette.base_dark; }
      ];

      label = [
        # Time
        {
          text = "cmd[update:1000] date +%H:%M";
          color = palette.text_primary;
          font_size = 96;
          font_family = "PxPlus IBM VGA 8x14";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        # Date in Russian
        {
          text = "cmd[update:60000] LC_TIME=ru_RU.utf8 date '+%A, %d %B'";
          color = palette.text_muted;
          font_size = 20;
          font_family = "PxPlus IBM VGA 8x14";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        # Status label
        {
          text = "БЛОК";
          color = palette.rust;
          font_size = 16;
          font_family = "PxPlus IBM VGA 8x14";
          position = "0, -40";
          halign = "center";
          valign = "center";
        }
        # Keyboard layout indicator
        {
          text = "$LAYOUT[en,ru]";
          font_family = "PxPlus IBM VGA 8x14";
          font_size = 16;
          color = palette.text_muted;
          position = "200, -100";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          size = "320, 44";
          outline_thickness = 1;
          dots_size = 0.2;
          dots_spacing = 0.3;
          dots_center = true;
          outer_color = palette.rust;
          inner_color = palette.surface;
          font_color = palette.text_primary;
          font_family = "PxPlus IBM VGA 8x14";
          check_color = palette.ochre;
          fail_color = palette.warning_red;
          fade_on_empty = false;
          placeholder_text = "<span foreground=\"##7A7568\">введите пароль</span>"; # Note: HTML still uses hex without 'rgba' prefix usually, but Hyprlock accepts rgba strings too. If you want strict palette consistency, use: "<span foreground=\"${builtins.replaceStrings [\"rgba(\" \"FF)\"] [\"\" \"\"] palette.text_muted}\">введите пароль</span>"
          # Simpler approach for placeholder: Just hardcode or extract hex if needed, 
          # but often raw strings work best for HTML spans inside hyprlock. 
          # Let's stick to the palette variable for the main text, and assume the span needs specific formatting.
          
          hide_input = false;
          rounding = 0;
          shadow_passes = 0;
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
