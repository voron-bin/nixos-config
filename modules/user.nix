{ pkgs, user, ... }: {
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    users.${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      initialHashedPassword = "$6$U9b3cd0f4SoEp2J4$N7d4BUeei78D76lIzHbzYxKfq0C1pjC4pWhBXiGJUd4rPeek52b.VOiiql7AuXR16Awq2SsRlzBa9K3hMfPnQ/";
    };
  };
}
