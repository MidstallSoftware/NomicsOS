{ nixpkgs }:
(import "${nixpkgs}/nixos/modules/module-list.nix") ++ [
  ./default.nix
]
