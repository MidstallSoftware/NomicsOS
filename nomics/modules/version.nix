{ config, lib, ... }:
{
  config.system.nixos = {
    version = lib.mkForce (lib.nomics.trivial.release + config.system.nixos.versionSuffix);
    versionSuffix = lib.mkForce lib.nomics.trivial.versionSuffix;
    revision = lib.mkForce (lib.nomics.trivial.revisionWithDefault null);
    distroId = lib.mkForce "nomics";
    distroName = lib.mkForce "NomicsOS";
  };
}
