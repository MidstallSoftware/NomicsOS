{
  inputs = {
    nomics.url = "github:MidstallSoftware/NomicsOS";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    {
      self,
      nomics,
      flake-utils,
      systems,
    }:
    {
      nixosConfigurations = nomics.lib.genSystems {
        systems = import systems;
        config = nomics.lib.importJSON ./config.json;
      };
    };
}
