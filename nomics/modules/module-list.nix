{ nixpkgs, sops-nix }:
(import "${nixpkgs}/nixos/modules/module-list.nix") ++ [
  "${sops-nix}/modules/sops"
  ./default.nix
]
