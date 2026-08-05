# jagex-launcher

Nix flake packaging the official [Jagex Launcher](https://www.runescape.com/launcher) (for
RuneScape and Old School RuneScape) as an AppImage, wired up to launch nixpkgs `pkgs.runelite` or `pkgs.hdos` instead of the
AppImage packaged RuneLite client.

## Usage

Run directly:

```sh
nix run github:kurtmorris/jagex-launcher-flake
```

By default the launcher redirects to `runelite` from nixpkgs. A `jagex-launcher-hdos` variant is
also exposed, which redirects to `hdos` instead. Override `clientPkg` via the overlay or
`callPackage` to point at a different client entirely.

## System flake usage

Add this repo as an input in your system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jagex-launcher = {
      url = "github:kurtmorris/jagex-launcher-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, jagex-launcher, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        jagex-launcher.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

```nix
# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jagex-launcher ];
}
```
OR
```nix
# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jagex-launcher-hdos ];
}
```


If you'd rather not pull in the overlay (e.g. to avoid touching `pkgs` globally), reference the
package directly instead of importing the module:

```nix
{ inputs, ... }:
{
  environment.systemPackages = [
    inputs.jagex-launcher.packages.x86_64-linux.default
    # or the hdos variant:
    # inputs.jagex-launcher.packages.x86_64-linux.jagex-launcher-hdos
  ];
}
```

Since the launcher is unfree, `nixpkgs.config.allowUnfree = true;` needs to be set wherever your
system's `pkgs` is instantiated (you likely already have this if you use other unfree packages).

After adding the input, run `nix flake lock --update-input jagex-launcher` (or `nix flake
update`) in your system flake directory, then rebuild as usual.

## Note on licensing

The Jagex Launcher itself is proprietary software (`lib.licenses.unfree`); this flake only
packages the download and integration, it does not relicense the binary.
