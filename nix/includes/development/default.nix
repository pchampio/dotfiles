{ config, pkgs, ... }:

{
  imports =
    [
      ./containers.nix
      ./go.nix
      ./vscodenix
    ];

  nixpkgs.config = {
    android_sdk = {
      accept_license = true;
    };
  };

  home.packages = (with pkgs; [
    fuse
    gnupg
    # Dart
    dart

    # Flutter
    # flutter

    # Go
    go

    # Make
    gnumake

    # JavaScript
    nodejs
    yarn

    # Python
    pipenv
    python
    pythonPackages.virtualenv
  ]);
}
