{
  description = "Nix package for the official Jagex Launcher (RuneScape and Old School RuneScape)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {
        jagex-launcher = pkgs.callPackage ./jagex-launcher.nix { };
        jagex-launcher-hdos = pkgs.callPackage ./jagex-launcher.nix {
          clientPkg = pkgs.hdos;
          pname = "jagex-launcher-hdos";
        };
        default = self.packages.${system}.jagex-launcher;
      };

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/jagex-launcher";
      };

      overlays.default = final: prev: {
        jagex-launcher = final.callPackage ./jagex-launcher.nix { };
        jagex-launcher-hdos = final.callPackage ./jagex-launcher.nix {
          clientPkg = final.hdos;
          pname = "jagex-launcher-hdos";
        };
      };

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.jagex-launcher;
        in
        {
          options.programs.jagex-launcher = {
            enable = lib.mkEnableOption "the Jagex Launcher";

            client = lib.mkOption {
              type = lib.types.package;
              default = pkgs.runelite;
              defaultText = lib.literalExpression "pkgs.runelite";
              example = lib.literalExpression "pkgs.hdos";
              description = ''
                Client package the launcher starts in place of its bundled RuneLite AppImage.
                Its `meta.mainProgram` is the binary that gets executed.
              '';
            };

            package = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              default = pkgs.jagex-launcher.override { clientPkg = cfg.client; };
              defaultText = lib.literalExpression "pkgs.jagex-launcher.override { clientPkg = cfg.client; }";
              description = "The resulting launcher package, wired up to `client`.";
            };
          };

          config = lib.mkMerge [
            { nixpkgs.overlays = [ self.overlays.default ]; }
            (lib.mkIf cfg.enable { environment.systemPackages = [ cfg.package ]; })
          ];
        };
    };
}
