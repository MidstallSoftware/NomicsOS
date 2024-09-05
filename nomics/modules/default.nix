{ pkgs, ... }:
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
}
