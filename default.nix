# default.nix in a blank folder
{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./jagex-launcher.nix {}
