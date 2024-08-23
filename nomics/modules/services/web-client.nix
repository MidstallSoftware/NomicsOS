{ config, pkgs, lib, ... }:
let
  cfg = config.nomics.services.web-client;

  mkFirewallOptions = { port }:
    lib.mkMerge [
      (lib.mkIf (cfg.iface != null) {
        interfaces."${cfg.iface}".allowedTCPPorts = [
          port
        ];
      })
      (lib.mkIf (cfg.iface == null) {
        allowedTCPPorts = [
          port
        ];
      })
    ];
in
{
  options = {
    nomics.services.web-client = {
      ssl = {
        enable = lib.mkEnableOption "Use SSL on the Nomics Web Client server.";
        port = lib.mkOption {
          type = with lib.types; port;
          default = 443;
          description = "Port to use for HTTPS for the Nomics Web Client server.";
        };
      };
      ipv4 = {
        enable = lib.mkEnableOption "Enable listening on IPv4" // { default = true; };
        addr = lib.mkOption {
          type = with lib.types; str;
          default = "0.0.0.0";
          description = "IP address.";
        };
        port = lib.mkOption {
          type = with lib.types; port;
          default = 80;
          description = "Port to use for HTTP for the Nomics Web Client server.";
        };
        ssl = {
          enable = lib.mkEnableOption "Use SSL on IPv4.";
          port = lib.mkOption {
            type = with lib.types; port;
            default = cfg.ssl.port;
            defaultText = lib.literalExpression "config.nomics.services.web-client.ssl.port";
            description = "Port to use for HTTPS on IPv4.";
          };
        };
      };
      ipv6 = {
        enable = lib.mkEnableOption "Enable listening on IPv6" // { default = true; };
        addr = lib.mkOption {
          type = with lib.types; str;
          default = "::0";
          description = "IP address.";
        };
        port = lib.mkOption {
          type = with lib.types; port;
          default = 80;
          description = "Port to use for HTTP for the Nomics Web Client server.";
        };
        ssl = {
          enable = lib.mkEnableOption "Use SSL on IPv6.";
          port = lib.mkOption {
            type = with lib.types; port;
            default = cfg.ssl.port;
            defaultText = lib.literalExpression "config.nomics.services.web-client.ssl.port";
            description = "Port to use for HTTPS on IPv6.";
          };
        };
      };
      hostname = lib.mkOption {
        description = "Nomics Web Client hostname override.";
        default = config.networking.hostName;
        defaultText = lib.literalExpression "config.networking.hostName";
        type = with lib.types; str;
      };
      iface = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Specific network interface to listen on";
      };
    };
  };

  config = lib.mkMerge [
    {
      services.nginx.virtualHosts."${cfg.hostname}" = {
        serverName = cfg.hostname;
        default = true;
        root = pkgs.nomics.web-client.default;
        extraConfig = ''
          index index.html;
        '';
        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
        };
      };
    }

    # Addresses
    (lib.mkIf (cfg.ipv4.enable) {
      networking.firewall = mkFirewallOptions {
        inherit (cfg.ipv4) port;
      };

      services.nginx.virtualHosts."${cfg.hostname}".listen = [
        {
          inherit (cfg.ipv4) addr port;
        }
      ];
    })
    (lib.mkIf (cfg.ipv6.enable) {
      networking.firewall = mkFirewallOptions {
        inherit (cfg.ipv6) port;
      };

      services.nginx.virtualHosts."${cfg.hostname}".listen = [
        {
          inherit (cfg.ipv6) port;
          addr = "[${cfg.ipv6.addr}]";
        }
      ];
    })

    # SSL
    (lib.mkIf (cfg.ssl.enable) {
      networking.firewall = mkFirewallOptions {
        inherit (cfg.ssl) port;
      };
    })
    (lib.mkIf (cfg.ipv4.enable && cfg.ipv4.ssl.enable) {
      networking.firewall = mkFirewallOptions {
        inherit (cfg.ipv4.ssl) port;
      };

      services.nginx.virtualHosts."${cfg.hostname}".listen = [
        {
          inherit (cfg.ipv4.ssl) port;
          inherit (cfg.ipv4) addr;
        }
      ];
    })
    (lib.mkIf (cfg.ipv6.enable && cfg.ipv6.ssl.enable) {
      networking.firewall = mkFirewallOptions {
        inherit (cfg.ipv6.ssl) port;
      };

      services.nginx.virtualHosts."${cfg.hostname}".listen = [
        {
          inherit (cfg.ipv6.ssl) port;
          addr = "[${cfg.ipv6.addr}]";
          ssl = true;
        }
      ];
    })
  ];
}
