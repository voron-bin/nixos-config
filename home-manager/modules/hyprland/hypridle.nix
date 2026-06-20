{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
	lock_cmd = "pidof hyprlock || hyprlock";
      };

      listener = [
        {
          timeout = 10;
          on-timeout = "notify-send 'You are idle!'";
          on-resume = "notify-send 'Welcome back!'";
        }
        {
          timeout = 100;
          on-timeout = "loginctl lock-session";
        }

        {
          timeout = 120;
          on-timeout = "systemctl suspend-then-hibernate";
        }
      ];
    };
  };
}
