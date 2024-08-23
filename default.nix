let
  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs = builtins.fetchTree flakeLock.nodes.nixpkgs.locked;
in
{ overlays ? [], config ? {}, ... }@args:
(import nixpkgs.outPath) ({
  overlays = [
    (import ./pkgs/default.nix {
      lib = (import "${nixpkgs.outPath}/lib").extend (import ./lib/overlay.nix {
        inherit nixpkgs;
      });
      outPath = ./.;
    })
  ] ++ args.overlays or [];
} // builtins.removeAttrs args [ "overlays" ])
