{
  description = "Declarative AppImage installer for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    nixosModules.default = import ./module.nix;
    nixosModules.appimages = import ./module.nix;
    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        prefetch-appimage = pkgs.writeShellApplication {
          name = "prefetch-appimage";
          runtimeInputs = [ pkgs.jq ];
          text = builtins.readFile ./prefetch.sh;
        };
      }
    );
    apps = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: {
      prefetch-appimage = {
        type = "app";
        program = nixpkgs.lib.getExe self.packages.${system}.prefetch-appimage;
      };
      add = {
        type = "app";
        program = nixpkgs.lib.getExe self.packages.${system}.prefetch-appimage;
      };
    });
  };
}
