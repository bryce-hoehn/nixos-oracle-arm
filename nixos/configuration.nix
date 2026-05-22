{ config, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (modulesPath + "/virtualisation/oci-image.nix")
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "oci-nixos-arm"; # TARGET_HOSTNAME
  time.timeZone = "UTC"; # TARGET_TIMEZONE
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Dynamic user block wrapper
  users.users = let 
    user = "opc"; # TARGET_USERNAME
  in {
    "${user}" = {
      isNormalUser = true;
      description = "${user} Admin User"; # TARGET_DESCRIPTION
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        "" # TARGET_SSH_KEY
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.05";
}
