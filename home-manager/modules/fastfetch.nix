{ pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "auto";
        padding = {
          top = 1;
          right = 3;
        };
      };
      
      display = {
        separator = " ► ";
        color = {
          keys = "red";
          title = "white";
          output = "white";
          separator = "red";
        };
        key = {
          width = 8;
        };
      };
      
      modules = [
        "break"
        {
          type = "title";
          format = "{user-name-colored}{at-symbol-colored}{host-name-colored}";
          color = {
            user = "red";
            at = "8";
            host = "white";
          };
        }
        {
          type = "custom";
          format = "═════════════════════════════════════";
        }
        { type = "os"; key = "ОС"; }
        { type = "kernel"; key = "ЯДРО"; }
        { type = "uptime"; key = "ВРЕМЯ"; }
        { type = "packages"; key = "ПКТ"; }
        { type = "shell"; key = "ОБЛ"; }
        { type = "wm"; key = "ОКН"; }
        { type = "terminal"; key = "ТЕРМ"; }
        {
          type = "custom";
          format = "═════════════════════════════════════";
        }
        {
          type = "cpu";
          key = "ЦП";
          format = "{name} ({cores-physical}C/{cores-logical}T)";
        }
        { type = "gpu"; key = "ГП"; }
        { type = "memory"; key = "ОЗУ"; }
        {
          type = "disk";
          key = "ДИСК";
          folders = "/";
        }
        { type = "display"; key = "МОН"; }
        {
          type = "custom";
          format = "═════════════════════════════════════";
        }
        "break"
        {
          type = "colors";
          symbol = "block";
        }
      ];
    };
  };
}
