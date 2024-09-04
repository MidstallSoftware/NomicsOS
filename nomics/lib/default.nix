{ lib }:
rec {
  importJSONModule = p: { lib, ... }:
    let
      dirname = lib.removeSuffix (lib.toString p) "${builtins.baseNameOf p}";
      config = lib.importJSON p;
    in {
      imports = lib.map importJSONModule (lib.map (i: "${dirname}/${i}") (config.imports or []));

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
