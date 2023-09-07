{ config, pkgs, ... }:

{
  programs.go = {
    enable = true;
    goPath = "~/lab/go";
  };
}
