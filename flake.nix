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
                # strips the "kvm" feature restriction for the runner
                (final: prev: {
                  nixos-disk-image = prev.nixos-disk-image.overrideAttrs (oldAttrs: {
                    requiredSystemFeatures = [ ];
                  });
                })

                # https://github.com/nix-community/nixos-generators/issues/443#issuecomment-3697547318
                (final: prev: {
                  lkl = prev.lkl.overrideAttrs (old: {
                    postPatch = (old.postPatch or "") + ''
                      substituteInPlace tools/lkl/cptofs.c \
                        --replace-fail 'lkl_start_kernel("mem=100M")' 'lkl_start_kernel("mem=1024M")'
                    '';
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
