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

  npmDepsHash = "sha256-ac4ChmXNOEt8u4llu2rpCQFJR/gj1cvOULj0lXlROZk=";

  installPhase = ''
    npm run build
    mv dist $out
  '';
}
