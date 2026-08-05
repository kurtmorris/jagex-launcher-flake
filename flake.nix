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

      nixosModules.default = { ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
