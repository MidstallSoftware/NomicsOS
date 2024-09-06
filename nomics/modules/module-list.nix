{ nixpkgs, sops-nix, disko }:
(import "${nixpkgs}/nixos/modules/module-list.nix") ++ [
  "${sops-nix}/modules/sops"
  "${disko}/module.nix"
  ./default.nix
]
