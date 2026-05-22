{
  description = "NixOS configuration flake for Oracle Cloud ARM Free Tier";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # TARGET_FLAKE_CONFIG
    nixosConfigurations.oci-nixos-arm = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}
