{ config, pkgs, ... }:

{
  home.packages = (with pkgs; [
    direnv
    unzip
    curl
    wget
    zsh
  ]);

  programs.direnv.enable = true;
  programs.ssh.enable = true;
  programs.zsh.enable = true;
}
