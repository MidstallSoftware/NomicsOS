{
  imports = [
    ./version.nix
    ./services/web-client.nix
  ];

  services.nginx.enable = true;
}
