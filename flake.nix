{
  description = "A cloud-container based operating system built around NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    systems.url = "github:nix-systems/default-linux";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      systems,
      sops-nix,
      disko,
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
                  }@args:
                  let
                    nomics =
                      system:
                      f.nomicsSystem {
                        modules = [
                          (f.nomics.os.importJSONModule config)
                          { nixpkgs.hostPlatform = system; }
                        ] ++ modules;
                      };
                  in
                  f.genAttrs
                    (f.map (v: "${v}/${(nomics v).config.networking.hostName}") (
                      args.systems or (import imports.systems)
                    ))
                    (
                      attrName:
                      let
                        system = f.elemAt (f.splitString "/" attrName) 0;
                      in
                      nomics system
                    );
              };
              nomicsSystem =
                args:
                p.nixosSystem (
                  {
                    baseModules = import ./nomics/modules/module-list.nix { inherit nixpkgs sops-nix disko; };
                    modules = args.modules or [ ] ++ [
                      {
                        nixpkgs.overlays = [
                          self.overlays.default
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
        devShells = lib.mapAttrs (_: v: v.devShell.overrideAttrs (f: _: {
          nomicsOptionPages = self.nixosConfigurations."${v.devShell.system}/qemu-vm".config.system.build.nomics-option-pages;
          nomicsOptions = self.nixosConfigurations."${v.devShell.system}/qemu-vm".config.system.build.nomics-options;
        })) packages;
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
        config = builtins.toFile "config.json" (builtins.toJSON { hostname = "qemu-vm"; });
      };

      templates.default = {
        path = ./nomics/template;
        description = "A basic Nomics OS setup";
      };
    };
}
