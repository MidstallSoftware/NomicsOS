{ lib }:
rec {
  importJSONModule = p: { lib, ... }:
    let
      config = lib.importJSON p;
    in {
      imports = lib.map importJSONModule (config.imports or []);

      config = lib.mkMerge [
        {
          nomics = lib.removeAttrs config [ "hostname" "imports" ];
        }
        (lib.mkIf (config ? hostname) {
          networking.hostName = config.hostname;
        })
      ];
    };
}
