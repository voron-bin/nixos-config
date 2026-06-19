{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "voronezh";
      theme_background = true;
      truecolor = true;
      force_tty = false;
      disable_presets = "Off";
      base_10_sizes = false;
      show_battery = false;
      show_battery_watts = true;
      log_level = "WARNING";
      save_config_on_exit = true;
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = true;
      shown_gpus = "nvidia amd intel";
    };
  };

  # Place the theme file into the correct directory for btop to find it
  xdg.configFile."btop/themes/voronezh.theme".source = ./voronezh.theme;
}
