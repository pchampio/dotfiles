{ config, pkgs, ... }:

{

  imports = [
    ./includes/development/default.nix
    ./includes/shell/default.nix
    ./includes/app/default.nix
    ./includes/desktop/default.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "pchampio";
  home.homeDirectory = "/home/pchampio";


  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.
}
