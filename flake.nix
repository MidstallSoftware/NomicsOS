{
  description = "A cloud-container based operating system built around NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default-linux";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      systems,
      sops-nix,
    }@imports:
    let
      libVersionInfoOverlay = import ./lib/flake-version-info.nix self;

      lib =
        ((nixpkgs.lib.extend (import ./lib/overlay.nix { inherit nixpkgs; })).extend (
          libVersionInfoOverlay
        )).extend
          (
            f: p: {
              nomics = p.nomics // {
                os = import ./nomics/lib { lib = f; };

                genSystems =
                  {
                    systems ? (import imports.systems),
                    modules ? [ ],
                    config ? { },
                  }:
                  f.genAttrs (f.map (v: "${v}/${config.hostname}") systems) (
                    attrName:
                    let
                      system = f.removeSuffix "/${config.hostname}" attrName;
                    in
                    f.nomicsSystem {
                      modules = [
                        (
                          { lib, ... }:
                          {
                            nixpkgs.hostPlatform = system;
                            networking.hostName = config.hostname;
                            nomics = lib.removeAttrs config [ "hostname" ];
                          }
                        )
                      ] ++ modules;
                    }
                  );
              };
              nomicsSystem =
                args:
                p.nixosSystem (
                  {
                    baseModules = import ./nomics/modules/module-list.nix { inherit nixpkgs sops-nix; };
                    modules = args.modules or [ ] ++ [
                      {
                        nixpkgs.overlays = [
                          self.overlays.default
                          sops-nix.overlays.default
                        ];
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
          sops-nix.overlays.default
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

      nixosConfigurations = lib.nomics.genSystems {
        modules = [ ./nomics/modules/virtualisation/qemu-vm.nix ];
        config.hostname = "qemu-vm";
      };

      templates.default = {
        path = ./nomics/template;
        description = "A basic Nomics OS setup";
      };
    };
}
