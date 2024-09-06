{ config, lib, pkgs, ... }:
{
  imports = [
    ./options.nix
    ./users.nix
    ./version.nix
    ./services/api-control.nix
    ./services/web-client.nix
  ];

  environment.systemPackages = with pkgs; [ sops git ];

  sops.age = {
    keyFile = "/var/lib/nomics/secret-key.txt";
    generateKey = true;
  };

  services.nginx.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.grub.devices = lib.mkIf (!(config.system.build ? vm) && builtins.hasAttr config.disko.devices.disk config.networking.hostName) [
    config.disko.devices.disk."${config.networking.hostName}".device
  ];
}
