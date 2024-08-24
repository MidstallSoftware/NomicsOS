{
  imports = [
    ./version.nix
    ./services/api-control.nix
    ./services/web-client.nix
  ];

  services.nginx.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
