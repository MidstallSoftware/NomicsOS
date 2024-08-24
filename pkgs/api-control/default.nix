{
  lib,
  buildDartApplication,
  dart,
  version,
  path,
  runCommand,
}:
buildDartApplication {
  pname = "nomics-api-control";
  inherit version;

  src = path;
  sourceRoot = "source/pkgs/api-control";

  dartOutputType = "exe";

  dartEntryPoints = {
    "bin/nomics-api-control" = "bin/nomics-api-control.dart";
  };

  dartCompileFlags = [
    "-Dflags.hot-reload=false"
  ];

  sdkSourceBuilders = {
    # https://github.com/dart-lang/pub/blob/e1fbda73d1ac597474b82882ee0bf6ecea5df108/lib/src/sdk/dart.dart#L80
    "dart" = name: runCommand "dart-sdk-${name}" { passthru.packageRoot = "."; } ''
      for path in '${dart}/pkg/${name}'; do
        if [ -d "$path" ]; then
          ln -s "$path" "$out"
          break
        fi
      done

      if [ ! -e "$out" ]; then
        echo 1>&2 'The Dart SDK does not contain the requested package: ${name}!'
        exit 1
      fi
    '';
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  meta.mainProgram = "nomics-api-control";
}
