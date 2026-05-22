{
  description = "NixOS QCOW2 Image Builder for Oracle Cloud ARM64 Free Tier";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }: {
    packages.x86_64-linux.oci-arm64 = nixos-generators.lib.nixosGenerate {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/oci-image.nix"

        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-linux";
          networking.useDHCP = nixpkgs.lib.mkForce true;
          networking.predictableInterfaceNames = true;
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;

          # Bootstrap SSH config so you can log in the first time
          services.openssh.enable = true;
          users.users.opc = {
            isNormalUser = true;
            description = "Oracle Cloud User";
            extraGroups = [ "networkmanager" "wheel" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...your_key_here..."
            ];
          };
          security.sudo.wheelNeedsPassword = false;

          # Read files from your repo and write them straight into /etc/nixos/
          environment.etc = {
            "nixos/flake.nix".text = builtins.readFile ./nixos/flake.nix;
            "nixos/configuration.nix".text = builtins.readFile ./nixos/configuration.nix;
            "nixos/hardware-configuration.nix".text = builtins.readFile ./nixos/hardware-configuration.nix;
          };
        })
      ];
      format = "qcow2";
    };
  };
}
