{ config, pkgs, ... }:

{
  home.packages = (with pkgs; [
    direnv
    zsh
    tmux
  ]);

  programs.direnv.enable = true;
  programs.ssh.enable = true;
  programs.zsh.enable = true;
}
