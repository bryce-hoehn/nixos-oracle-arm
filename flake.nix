{
  description = "NixOS QCOW2 Image Builder running natively on ARM64 runners";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }: {
    packages.aarch64-linux.oci-arm64 = nixos-generators.nixosGenerate {
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      format = "qcow";

      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
        ./nixos/configuration.nix

        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            (final: prev: {
              # This strips the "kvm" requirement from the final disk image generator derivation
              nixos-disk-image = prev.nixos-disk-image.overrideAttrs (oldAttrs: {
                requiredSystemFeatures = [ ];
              });
            })
          ];
          nixpkgs.hostPlatform = "aarch64-linux";
          networking.useDHCP = nixpkgs.lib.mkForce true;
          networking.usePredictableInterfaceNames = true;

          environment.etc = {
            "nixos/flake.nix".text = builtins.readFile ./nixos/flake.nix;
            "nixos/configuration.nix".text = builtins.readFile ./nixos/configuration.nix;
            "nixos/hardware-configuration.nix".text = builtins.readFile ./nixos/hardware-configuration.nix;
          };
        })
      ];
    };
  };
}
