{
  lib,
  buildNpmPackage,
  version,
  path,
  writeText,
}:
buildNpmPackage {
  pname = "nomics-web-client";
  inherit version;

  src = path;
  sourceRoot = "source/pkgs/web-client";

  npmDepsHash = "sha256-sOEcnFonDu8B7dGJF5TAnH38He3cyXxz9tUuN6DYXjY=";

  installPhase = ''
    npm run build
    mv dist $out
  '';
}
