{ lib }:
rec {
  importJSONModule = p: { lib, ... }:
    let
      dirname = lib.removeSuffix "${builtins.baseNameOf p}" (builtins.toString p);
      config = lib.importJSON p;
    in {
      imports = lib.map importJSONModule (lib.map (i: "${dirname}/${i}") (config.imports or []));

      config = lib.mkMerge [
        {
          nomics = lib.removeAttrs config [ "hostname" "imports" "storage" ];
        }
        (lib.mkIf (config ? hostname) {
          networking.hostName = config.hostname;
        })
        (lib.mkIf (config ? storage) {
          disko.devices = config.storage;
        })
      ];
    };
}
