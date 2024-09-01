{ config, pkgs, lib, ... }:
let
  cfg = config.nomics.services.api-control;

  cmdArgs = [
    "--address"
    "/var/lib/nomics-api-control.sock"
    "--pgsql-socket"
    "--pgsql-host"
    "/var/run/postgresql/.s.PGSQL.${toString config.services.postgresql.settings.port}"
    "--pgsql-username"
    "nomics"
    "--options-json"
    config.system.build.nomics-options
    "--option-pages-json"
    config.system.build.nomics-option-pages
  ];
in
{
  config = {
    systemd.services.nomics-api-control = {
      before = [ "nginx.service" ];
      after = [ "networking.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      description = "Nomics API Control Server";
      path = [ pkgs.git config.nix.package ];
      preStart = ''
        ${pkgs.coreutils}/bin/rm -f /var/lib/nomics-api-control.sock
      '';
      serviceConfig.ExecStart = "${lib.getExe pkgs.nomics.api-control.default} ${toString cmdArgs}";
    };

    services = {
      nginx.virtualHosts."${config.nomics.services.web-client.hostname}".locations."/api" = {
        proxyPass = "http://unix:/var/lib/nomics-api-control.sock";
        extraConfig = ''
          rewrite /api/(.*) /$1 break;
          proxy_redirect off;
          proxy_set_header Host $host;
        '';
      };
      postgresql = {
        enable = true;
        ensureDatabases = [ "nomics" ];
        ensureUsers = [{
          name = "nomics";
          ensureDBOwnership = true;
        }];
        authentication = ''
          local nomics nomics trust
        '';
      };
    };
  };
}
