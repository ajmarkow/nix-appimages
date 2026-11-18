# nix-appimages

Declarative AppImage installer for NixOS. List URLs, get wrapped packages
with desktop entries and icons.

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

## Design choices

- `wrapType2` over raw `appimage-run`: full FHS env, launcher integration.
  Raw binfmt alone leaves no `.desktop` or icons.
- `finalAttrs.contents` over separate `extract`: one extraction, no drift.
- Attrset keyed by name, not a list: name becomes `pname`, binary, and
  desktop filename. Simple to override per app.
- Hash required: Nix purity. Get it with `nix-prefetch-url --type sha256`.
- Enables `programs.appimage` + binfmt by default so unpackaged AppImages
  still run directly.
- Desktop file defaults to `<name>.desktop`, `Exec=AppRun` rewritten to
  the wrapper binary.
- Icons auto-copied from `usr/share/icons` unless `iconPath` pins one file.
- `extraPkgs` / `extraBwrapArgs` passthrough for apps needing extra libs.

## Use

```nix
{
  inputs.nix-appimages.url = "github:you/nix-appimages";

  outputs = { nixpkgs, nix-appimages, ... }: {
    nixosConfigurations.mine = nixpkgs.lib.nixosSystem {
      modules = [ nix-appimages.nixosModules.default ./configuration.nix ];
    };
  };
}
```

```nix
{ ... }:
{
  programs.appimages = {
    enable = true;
    apps = {
      cursor = {
        url = "https://downloader.cursor.sh/linux/appImage/x64";
        hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        version = "0.40.3";
      };
      beeper = {
        url = "https://example.com/Beeper.AppImage";
        hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
        extraPkgs = pkgs: [ pkgs.at-spi2-core ];
      };
    };
  };
}
```

Get the hash without manual work:

```
nix run github:you/nix-appimages#prefetch-appimage -- <url> [name]
```

Prints a ready-to-paste `programs.appimages.apps` entry. Hash stays in
config for purity; the helper does the prefetch for you.

## Options

- `url`, `hash`, `version` — what to fetch and what to call it.
- `desktopFile` — .desktop name inside the AppImage (default `<name>.desktop`).
- `iconPath` — explicit icon path inside the AppImage; when unset, copies
  `usr/share/icons` if present.
- `extraPkgs` — `pkgs: [...]` added to the FHS env (e.g. `at-spi2-core`).
- `extraBwrapArgs` — extra bubblewrap args.
- `binfmt` — register binfmt_misc so raw AppImages run directly (default true).

## Notes

Built on `pkgs.appimageTools.wrapType2` per the nixpkgs manual
(sec-pkgs-appimageTools). Uses `finalAttrs.contents` for the extracted
files. Debug missing desktop/icon names with
`APPIMAGE_DEBUG_EXEC=bash appimage-run <file>`.
