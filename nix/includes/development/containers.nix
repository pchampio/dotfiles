{ config, pkgs, ... }:

{
  home.packages = (with pkgs; [
    containerd
    docker_compose
    runc
  ]);
}
