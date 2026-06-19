{ user, ... }: {
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "iikeep-since 4d --keep 5";
    flake = "/home/${user}/flake";
  };
}
