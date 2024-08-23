{
  description = "A cloud-container based operating system built around NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      systems,
    }:
    let
      libVersionInfoOverlay = import ./lib/flake-version-info.nix self;

      lib = ((nixpkgs.lib.extend (import ./lib/overlay.nix {
        inherit nixpkgs;
      })).extend (libVersionInfoOverlay)).extend (
        f: p: {
          nomics = p.nomics // {
            os = import ./nomics/lib { lib = f; };
          };
          nomicsSystem =
            args:
            p.nixosSystem (
              {
                baseModules = import ./nomics/modules/module-list.nix { inherit nixpkgs; };
                modules = args.modules or [ ] ++ [
                  {
                    nixpkgs.overlays = [ self.overlays.default ];
                    nixpkgs.flake.source = lib.mkForce self.outPath;
                  }
                ];
              }
              // builtins.removeAttrs args [ "modules" ]
            );
        }
      );
    in
    flake-utils.lib.eachSystem (import systems) (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          (f: p: { inherit lib; })
          self.overlays.default
        ];

        packages = lib.genAttrs pkgs.nomics.__packages (p: pkgs.nomics.${p});
      in
      {
        legacyPackages = pkgs;

        packages = lib.mapAttrs (_: v: v.default) packages;
        devShells = lib.mapAttrs (_: v: v.devShell) packages;
      }
    )
    // {
      inherit lib;

      overlays.default = import ./pkgs {
        inherit lib;
        inherit (self) outPath;
      };

      nixosModules.default = import ./nomics/modules/default.nix;

      nixosConfigurations = lib.genAttrs (lib.map (p: "${p}/qemu-vm") (import systems)) (
        attrName:
        let
          system = lib.removeSuffix "/qemu-vm" attrName;
        in
        lib.nomicsSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./nomics/modules/virtualisation/qemu-vm.nix
          ];
        }
      );
    };
}
