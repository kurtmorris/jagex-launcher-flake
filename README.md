# jagex-launcher

Nix flake packaging the official [Jagex Launcher](https://www.runescape.com/launcher) (for
RuneScape and Old School RuneScape) as an AppImage, wired up to launch RuneLite instead of the
stock Java client.

## Usage

Run directly:

```sh
nix run github:kurtmorris/jagex-launcher-flake
```

Or add it to your system/home-manager config:

```nix
{
  inputs.jagex-launcher.url = "github:kurtmorris/jagex-launcher-flake";

  # then, e.g. in your packages list:
  environment.systemPackages = [ inputs.jagex-launcher.packages.x86_64-linux.default ];
}
```

By default the launcher redirects to `runelite` from nixpkgs. Override `clientPkg` via the
overlay or `callPackage` to point at a different client.

## Note on licensing

The Jagex Launcher itself is proprietary software (`lib.licenses.unfree`); this flake only
packages the download and integration, it does not relicense the binary.
