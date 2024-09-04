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
      nixosConfigurations = nomics.lib.nomics.genSystems {
        systems = import systems;
        modules = [
          { sops.defaultSopsFile = ./secrets.yaml; }
        ];
        config = nomics.lib.nomics.os.importJSONModule ./config.json;
      };
    };
}
