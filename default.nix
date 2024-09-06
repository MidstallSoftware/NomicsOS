let
  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs = builtins.fetchTree flakeLock.nodes.nixpkgs.locked;
  sops-nix = builtins.fetchTree flakeLock.nodes.sops-nix.locked;
  disko = builtins.fetchTree flakeLock.nodes.disko.locked;
in
{
  overlays ? [ ],
  config ? { },
  ...
}@args:
(import nixpkgs.outPath) (
  {
    overlays = [
      (import ./pkgs/default.nix {
        lib = (import "${nixpkgs.outPath}/lib").extend (import ./lib/overlay.nix { inherit nixpkgs; });
        outPath = ./.;
      })
      (
        final: prev:
        let
          localPkgs = import "${sops-nix}/default.nix" { pkgs = final; };
        in
        {
          inherit (localPkgs)
            sops-install-secrets
            sops-init-gpg-key
            sops-pgp-hook
            sops-import-keys-hook
            sops-ssh-to-age
            ;
          # backward compatibility
          inherit (prev) ssh-to-pgp;
        }
      )
      (f: p: {
        disko = p.callPackage "${disko}/package.nix" { };
        disko-install = f.disko.overrideAttrs (_old: {
          name = "disko-install";
        });
      })
    ] ++ args.overlays or [ ];
  }
  // builtins.removeAttrs args [ "overlays" ]
)
