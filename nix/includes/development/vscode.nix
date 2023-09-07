{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      znck.grammarly
      valentjn.vscode-ltex
      sirmspencer.vscode-autohide
      mushan.vscode-paste-image
      James-Yu.latex-workshop
      brunnerh.altervista-thesaurus
      yy0931.go-to-next-error
      Gruntfuggly.activitusbar
    ];
  };
}

