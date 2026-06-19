{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      format = "[\\[](text_muted)$username[@](text_muted)$hostname[ ](text_muted)$directory[\\]](text_muted)$git_branch$git_status$cmd_duration$character ";
      add_newline = false;
      palette = "voronezh";

      palettes.voronezh = {
        base       = "#1C1917";
        surface    = "#262320";
        text       = "#D6CFC2";
        text_muted = "#7A7568";
        rust       = "#A84826";
        brick      = "#7A2E1F";
        ochre      = "#B89650";
        steel      = "#6B7278";
        warning    = "#C8302E";
        success    = "#7A8066";
      };

      username = {
        show_always = true;
        style_user = "text";
        style_root = "warning bold";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "text";
        format = "[$hostname]($style)";
      };

      directory = {
        style = "ochre";
        format = "[$path]($style)[$read_only]($read_only_style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        home_symbol = "~";
        read_only = " ";
        read_only_style = "warning";
      };

      git_branch = {
        symbol = "";
        style = "rust";
        format = " [on ](text_muted)[$symbol$branch]($style)";
      };

      git_status = {
        style = "ochre";
        format = " [\\[$all_status$ahead_behind\\]]($style)";
      };
    };
  };
}
