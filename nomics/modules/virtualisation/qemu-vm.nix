{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ "${lib.nomics.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix" ];

  config = {
    boot.postBootCommands = ''
      if ! [ -e /etc/nixos/flake.nix ] || ! [ -e /etc/nixos/config.json ]; then
        rm -rf /etc/nixos
        cp -r ${../../template} /etc/nixos
        cp ${
          pkgs.writeText "nomics-config.json" (
            lib.generators.toJSON { } (lib.removeAttrs config.nomics [ "users" ] // {
              hostname = config.networking.hostName;
              imports = [ "./config-users.json" ];
            })
          )
        } /etc/nixos/config.json
        cp ${
          pkgs.writeText "nomics-config-users.json" (
            lib.generators.toJSON { } { users = config.nomics.users; }
         )
        } /etc/nixos/config-users.json
        ${lib.getExe pkgs.git} init -b master /etc/nixos
      fi
    '';

    nomics = {
      services.web-client.iface = "eth0";
      users = [
        {
          name = "demo";
          password = "demo";
        }
      ];
    };

    virtualisation.qemu.networkingOptions = lib.mkForce [
      "-net nic,netdev=private.0,model=virtio"
      "-netdev user,id=private.0,net=10.0.2.0/24,hostfwd=tcp::8080-:80,\"$QEMU_NET_OPTS\""

      "-net nic,netdev=public.0,model=virtio"
      "-netdev user,id=public.0,net=10.0.3.0/24,\"$QEMU_NET_OPTS\""
    ];
  };
}
