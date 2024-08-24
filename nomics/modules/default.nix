{
  imports = [
    ./version.nix
    ./services/api-control.nix
    ./services/web-client.nix
  ];

  boot.postBootCommands = ''
    chmod 0 /etc/nixos/config.json
    chown root:root /etc/nixos/config.json
  '';

  services.nginx.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
