{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions;
    []
;
#    ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
#      {
#        name = "znck";
#        publisher = "grammarly";
#        version = "0.23.15";
#      }
#      { name = "vscode-ltex"; publisher = "valentjn"; version = "13.1.0"; }
#      { name = "vscode-autohide"; publisher = "sirmspencer"; version = "1.0.8"; }
#      { name = "vscode-paste-image"; publisher = "mushan"; version = "1.0.4"; }
#      { name = "latex-workshop"; publisher = "James-Yu"; version = "9.13.4"; }
#      { name = "altervista-thesaurus"; publisher = "brunnerh"; version = "0.2.1"; }
#      { name = "go-to-next-error"; publisher = "yy0931"; version = "1.0.7"; }
#      { name = "activitusbar"; publisher = "Gruntfuggly"; version = "0.0.47"; }
#    ];
  };
}

