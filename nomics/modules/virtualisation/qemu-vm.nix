{ lib, ... }:
{
  imports = [
    "${lib.nomics.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
  ];

  config = {
    nomics.services.web-client.iface = "eth0";

    virtualisation.qemu.networkingOptions = lib.mkForce [
      "-net nic,netdev=private.0,model=virtio"
      "-netdev user,id=private.0,net=10.0.2.0/24,hostfwd=tcp::8080-:80,\"$QEMU_NET_OPTS\""

      "-net nic,netdev=public.0,model=virtio"
      "-netdev user,id=public.0,net=10.0.3.0/24,\"$QEMU_NET_OPTS\""
    ];

    users.users.debug = {
      group = "wheel";
      isNormalUser = true;
      password = "debug";
    };
  };
}
