{ config, pkgs, ... }:

{
  home.file.".config/fontconfig/conf.d/01-emoji.conf".source = ./google-chrome/01-emoji.conf;

  home.packages = (with pkgs; [
    file
    inkscape
    virtmanager
    flatpak
    flameshot
    xfce.thunar
    unzip
    curl
    wget
    htop
    nvtop
    neofetch
    google-chrome
  ]);
# Set environment variables
  home.sessionVariables = {
    EDITOR   = "nvim";
  };
}
