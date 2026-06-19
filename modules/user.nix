{ pkgs, user, ... }: {
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    users.${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      # supposed to create a password for the user that is hashed so as to be hidden by viewers on github, but does not seem to be working
      # for now, use pssword ${user} while in root to make the password
      # initialHashedPassword = "$6$U9b3cd0f4SoEp2J4$N7d4BUeei78D76lIzHbzYxKfq0C1pjC4pWhBXiGJUd4rPeek52b.VOiiql7AuXR16Awq2SsRlzBa9K3hMfPnQ/";
    };
  };
}
