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
      format = "qcow2";

      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/oracle-compute-config.nix"
        ./nixos/configuration.nix

        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-linux";
          networking.useDHCP = nixpkgs.lib.mkForce true;
          networking.predictableInterfaceNames = true;

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
