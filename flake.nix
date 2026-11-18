{
  description = "Declarative AppImage installer for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    nixosModules.default = import ./module.nix;
    nixosModules.appimages = import ./module.nix;
  };
}
