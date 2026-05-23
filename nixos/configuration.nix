{ config, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (modulesPath + "/virtualisation/oci-image.nix")
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "oracle";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users."changeme" = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.05";
}
