{
  description = "NixOS QCOW2 Image Builder running natively on ARM64 runners";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    packages.aarch64-linux.oracle = 
      let
        systemConfig = nixpkgs.lib.nixosSystem {
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
            ./nixos/configuration.nix

            ({ pkgs, lib, ... }: {
              services.cloud-init.enable = true;

              nixpkgs.overlays = [
                (final: prev: {
                  # Strips the "kvm" requirement so it compiles cleanly on non-KVM ARM64 runners
                  nixos-disk-image = prev.nixos-disk-image.overrideAttrs (oldAttrs: {
                    requiredSystemFeatures = [ ];
                  });
                })
              ];

              nixpkgs.hostPlatform = "aarch64-linux";
              networking.useDHCP = lib.mkForce true;
              networking.usePredictableInterfaceNames = true;

              environment.etc = {
                "nixos/flake.nix".text = builtins.readFile ./flake.nix;
                "nixos/configuration.nix".text = builtins.readFile ./nixos/configuration.nix;
                "nixos/hardware-configuration.nix".text = builtins.readFile ./nixos/hardware-configuration.nix;
              };
            })
          ];
        };
      in
      systemConfig.config.system.build.image;
  };
}
