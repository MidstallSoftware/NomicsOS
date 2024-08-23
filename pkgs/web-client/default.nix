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

  npmDepsHash = "sha256-gicp9oLj6ofbbW0MM+pKkCihKOlXy9gJzoHXoiVmUEM=";

  installPhase = ''
    npm run build
    mv dist $out
  '';
}
