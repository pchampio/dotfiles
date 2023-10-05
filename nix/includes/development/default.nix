{ config, pkgs, ... }:

{
  imports =
    [
      ./containers.nix
      ./go.nix
      ./vscode.nix
    ];

  nixpkgs.config = {
    android_sdk = {
      accept_license = true;
    };
  };

  home.packages = (with pkgs; [
    git
    fuse
    gnupg
    openssl
    gnumake
    cmake
    gcc
    glibc
    coreutils

    pkgconfig
    libconfig
    blas

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
    python311
    python311Packages.pip
  ]);

  home.sessionVariables = {
    CUDA_PATH = pkgs.cudatoolkit;
    # LD_LIBRARY_PATH = "${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
  };
}
