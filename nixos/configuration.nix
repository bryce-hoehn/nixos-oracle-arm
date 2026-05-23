{ config, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "oracle";

  services.openssh.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users."changeme" = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "25.11";
}
