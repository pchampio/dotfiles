{ config, pkgs, ... }:

{
  home.file.".config/fontconfig/conf.d/01-emoji.conf".source = ./google-chrome/01-emoji.conf;

  home.packages = (with pkgs; [
      kitty
      firefox
      google-chrome
  ]);
# Set environment variables
  home.sessionVariables = {
    TERMINAL = "kitty";
  };
  programs.kitty = {
    enable = true;
  };
}
