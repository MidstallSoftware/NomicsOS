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

  npmDepsHash = "sha256-l9D1DHP4vX99UnsdiUMIWb3l2kYGrOiFBPvjQelpQiY=";

  installPhase = ''
    npm run build
    mv dist $out
  '';
}
