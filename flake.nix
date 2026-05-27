{
  description = "NixOS QEMU-UEFI disk image for Oracle Cloud Arm shapes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "aarch64-linux";

      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configuration.nix

          "${nixpkgs}/nixos/modules/image/images.nix"

          ({ ... }: {
            image.modules = {
              qemu-efi = { };
            };
          })

          ({ pkgs, lib, ... }: {
            services.cloud-init.enable = true;

            nixpkgs.overlays = [
              # strips the "kvm" feature restriction for the runner
              (final: prev: {
                nixos-disk-image = prev.nixos-disk-image.overrideAttrs (_oldAttrs: {
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

            environment.etc."nixos" = {
              source = null; # ensure nix places the subdir contents as files
              directory = {
                "flake.nix".text = builtins.readFile ./flake.nix;
                "configuration.nix".text = builtins.readFile ./nixos/configuration.nix;
                "hardware-configuration.nix".text = builtins.readFile ./nixos/hardware-configuration.nix;
              };
            };
          })
        ];
      };
    in
    {
      packages.${system}.oracle =
        nixos.config.system.build.images.qemu-efi;
    };
}
