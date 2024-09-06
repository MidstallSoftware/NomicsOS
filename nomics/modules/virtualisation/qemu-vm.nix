{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ "${lib.nomics.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix" ];

  config = {
    systemd.services.nomics-api-control.preStart = lib.mkAfter ''
      if ! [ -e /etc/nixos/flake.nix ] || ! [ -e /etc/nixos/config.json ]; then
        rm -rf /etc/nixos
        cp -r ${../../template} /etc/nixos
        cp ${
          pkgs.writeText "nomics-config.json" (
            lib.generators.toJSON { } (lib.removeAttrs config.nomics [ "users" ] // {
              hostname = config.networking.hostName;
              imports = [ "./config-users.json" "./config-storage.json" ];
            })
          )
        } /etc/nixos/config.json
        cp ${
          pkgs.writeText "nomics-config-users.json" (
            lib.generators.toJSON { } { users = config.nomics.users; }
         )
        } /etc/nixos/config-users.json
        cp ${
          pkgs.writeText "nomics-config-storage.json" (
            lib.generators.toJSON { } { storage = lib.filterAttrsRecursive (n: _: !(lib.hasPrefix "_" n)) config.disko.devices; }
         )
        } /etc/nixos/config-storage.json
        ${lib.getExe pkgs.git} init -b master /etc/nixos
        pushd /etc/nixos
        ${lib.getExe pkgs.git} add *
        GIT_COMMITTER_NAME="root" GIT_COMMITTER_EMAIL="root@localhost" GIT_AUTHOR_NAME="root" GIT_AUTHOR_EMAIL="root@localhost" \
          ${lib.getExe pkgs.git} commit -a -m "Initial Commit"

        nix flake update --override-input nomics ${../../../.}
        ${lib.getExe pkgs.git} add flake.lock
        GIT_COMMITTER_NAME="root" GIT_COMMITTER_EMAIL="root@localhost" GIT_AUTHOR_NAME="root" GIT_AUTHOR_EMAIL="root@localhost" \
          ${lib.getExe pkgs.git} commit --amend flake.lock --no-edit
        popd
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

    users.users.demo.group = "wheel";

    disko.devices.disk."${config.networking.hostName}" = {
      device = config.virtualisation.rootDevice;
      type = "disk";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };

    virtualisation = {
      qemu.networkingOptions = lib.mkForce [
        "-net nic,netdev=private.0,model=virtio"
        "-netdev user,id=private.0,net=10.0.2.0/24,hostfwd=tcp::8080-:80,\"$QEMU_NET_OPTS\""

        "-net nic,netdev=public.0,model=virtio"
        "-netdev user,id=public.0,net=10.0.3.0/24,\"$QEMU_NET_OPTS\""
      ];
      graphics = false;
      mountHostNixStore = false;
      useNixStoreImage = true;
      writableStore = true;
    };
  };
}
