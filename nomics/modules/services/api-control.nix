{ config, pkgs, lib, ... }:
let
  cfg = config.nomics.services.api-control;
in
{
  config = {
    systemd.services.nomics-api-control = {
      before = [ "nginx.service" ];
      after = [ "networking.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "Nomics API Control Server";
      preStart = ''
        ${pkgs.coreutils}/bin/rm -f /var/lib/nomics-api-control.sock
      '';
      serviceConfig.ExecStart = "${lib.getExe pkgs.nomics.api-control.default} --address /var/lib/nomics-api-control.sock";
    };

    services.nginx.virtualHosts."${config.nomics.services.web-client.hostname}".locations."/api" = {
      proxyPass = "http://unix:/var/lib/nomics-api-control.sock";
      extraConfig = ''
        rewrite /api(.*) /$1 break;
        proxy_redirect off;
        proxy_set_header Host $host;
      '';
    };
  };
}
