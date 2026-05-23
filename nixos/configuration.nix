{ config, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (modulesPath + "/virtualisation/oci-image.nix")
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "oracle"; # TARGET_HOSTNAME
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Dynamic user block wrapper
  users.users = let 
    user = "changeme"; # TARGET_USERNAME
  in {
    "${user}" = {
      isNormalUser = true;
      description = "${user} Admin User"; # TARGET_DESCRIPTION
      extraGroups = [ "networkmanager" "wheel" ];
      initialPassword = "changeme";
      openssh.authorizedKeys.keys = [
        "" # TARGET_SSH_KEY
      ];
    };
  };

  system.stateVersion = "24.05";
}
