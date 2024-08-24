{
  imports = [
    ./version.nix
    ./services/api-control.nix
    ./services/web-client.nix
  ];

  services.nginx.enable = true;
}
