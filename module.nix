{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.appimages;

  appOpts = {
    options = {
      url = mkOption {
        type = types.str;
        description = "URL of the .AppImage file.";
      };
      hash = mkOption {
        type = types.str;
        description = "SRI hash of the AppImage (nix-prefetch-url --type sha256).";
      };
      version = mkOption {
        type = types.str;
        default = "1.0.0";
        description = "Version string, used for the wrapper name.";
      };
      desktopFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Desktop file name inside the AppImage (e.g. myapp.desktop). Defaults to <name>.desktop.";
      };
      iconPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Icon path inside the AppImage (e.g. usr/share/icons/hicolor/512x512/apps/myapp.png). Auto-detected when null.";
      };
      extraPkgs = mkOption {
        type = types.functionTo (types.listOf types.package);
        default = _: [ ];
        description = "Extra packages for the FHS env, as a function pkgs: [...].";
      };
      extraBwrapArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra bubblewrap args passed to wrapType2.";
      };
    };
  };

  mkAppImagePkg =
    name: app:
    let
      src = pkgs.fetchurl {
        url = app.url;
        hash = app.hash;
      };
      desktopName = if app.desktopFile != null then app.desktopFile else "${name}.desktop";
    in
    pkgs.appimageTools.wrapType2 (finalAttrs: {
      pname = name;
      version = app.version;
      inherit src;
      extraPkgs = app.extraPkgs;
      extraBwrapArgs = app.extraBwrapArgs;
      extraInstallCommands = ''
        install -m 444 -D ${finalAttrs.contents}/${desktopName} $out/share/applications/${name}.desktop
        substituteInPlace $out/share/applications/${name}.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=${name}'
        ${optionalString (app.iconPath != null) ''
          install -m 444 -D ${finalAttrs.contents}/${app.iconPath} \
            $out/share/icons/hicolor/512x512/apps/${name}.png
        ''}
        ${optionalString (app.iconPath == null) ''
          if [ -d ${finalAttrs.contents}/usr/share/icons ]; then
            cp -r ${finalAttrs.contents}/usr/share/icons $out/share/
          fi
        ''}
      '';
    });
in
{
  options.programs.appimages = {
    enable = mkEnableOption "declarative AppImage installer";
    binfmt = mkOption {
      type = types.bool;
      default = true;
      description = "Register binfmt_misc so AppImages run directly.";
    };
    apps = mkOption {
      type = types.attrsOf (types.submodule appOpts);
      default = { };
      description = "AppImages to install, keyed by program name.";
      example = {
        cursor = {
          url = "https://downloader.cursor.sh/linux/appImage/x64";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          version = "0.40.3";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs.appimage.enable = true;
    programs.appimage.binfmt = cfg.binfmt;
    environment.systemPackages = mapAttrsToList mkAppImagePkg cfg.apps;
  };
}
