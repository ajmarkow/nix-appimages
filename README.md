# nix-appimages

This module installs AppImages as normal NixOS packages. You declare each app with a name, a URL, and a hash. The module wraps each AppImage and adds a launcher entry with icons.

```nix
programs.appimages = {
  enable = true;
  apps.cursor = {
    url = "https://downloader.cursor.sh/linux/appImage/x64";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    version = "0.40.3";
  };
};
```

## Use the module

1. Add this repository as a flake input.
2. Add `nixosModules.default` to your NixOS modules.
3. Set `programs.appimages.enable` to true.
4. Add one entry per app under `programs.appimages.apps`.

```nix
{
  inputs.nix-appimages.url = "github:ajmarkow/nix-appimages";

  outputs = { nixpkgs, nix-appimages, ... }: {
    nixosConfigurations.mine = nixpkgs.lib.nixosSystem {
      modules = [ nix-appimages.nixosModules.default ./configuration.nix ];
    };
  };
}
```

## Add a new app

1. Run `nix run .#add -- <url> [name]` from this repository.
2. Copy the printed entry into `programs.appimages.apps`.
3. Rebuild your system.

`add` is a short alias for `prefetch-appimage`. Both commands run the same helper. The helper downloads the file and prints the hash. It prints a ready entry for your config. Keep the hash in config. Nix requires the hash for pure evaluation.

From another directory, use the full reference.

```
nix run github:ajmarkow/nix-appimages#add -- <url> [name]
```

## Why these choices

- `wrapType2` builds a full runtime for each AppImage and integrates the launcher entry. Plain `appimage-run` does not install desktop files or icons.
- The module reads files from `finalAttrs.contents`. This uses one extraction and avoids drift between extract and wrap steps.
- Apps live in an attrset keyed by name. The name sets the package name, the binary name, and the desktop file name.
- Each app requires a hash. Nix requires the hash before download. The `add` helper fetches it for you.
- The module enables `programs.appimage` and binfmt by default. This also lets raw AppImage files run directly.
- The desktop file defaults to `<name>.desktop`. The module replaces `Exec=AppRun` with the wrapper binary name.
- The module copies `usr/share/icons` when `iconPath` is empty. Set `iconPath` to install one icon file instead.
- `extraPkgs` and `extraBwrapArgs` pass extra libraries and sandbox flags to apps that need them.

## Options

- `url`. Location of the AppImage file.
- `hash`. SRI hash of the file. Get it with `nix run .#add`.
- `version`. Version string for the wrapper package. Default is `1.0.0`.
- `desktopFile`. Desktop file name inside the AppImage. Default is `<name>.desktop`.
- `iconPath`. Icon path inside the AppImage. Default copies `usr/share/icons`.
- `extraPkgs`. Function of the form `pkgs: [...]`. It adds libraries to the runtime.
- `extraBwrapArgs`. List of extra sandbox flags.
- `binfmt`. Direct execution of raw AppImage files. Default is true.

## Notes

The module builds on `pkgs.appimageTools.wrapType2`. See the nixpkgs manual, section `sec-pkgs-appimageTools`. To find a missing desktop or icon name, run `APPIMAGE_DEBUG_EXEC=bash appimage-run <file>`.
