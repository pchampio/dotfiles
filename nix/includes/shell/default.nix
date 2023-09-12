{ config, pkgs, ... }:

{
  home.packages = (with pkgs; [
    direnv
    zsh
    tmux
    openssh
  ]);

  programs.direnv.enable = true;
  programs.ssh.enable = true;
  programs.zsh.enable = true;

  programs.bash = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  xdg = {
    enable=true;
    mime.enable = true;
    systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share/applications" ];
  };
  targets.genericLinux.enable = true;
}
