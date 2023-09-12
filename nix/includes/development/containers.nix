{ config, pkgs, ... }:

{
  home.packages = (with pkgs; [
    containerd
    docker-compose
    runc
  ]);
}
