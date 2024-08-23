{ nixpkgs }:
lib: prev: {
  nomics = lib.makeExtensible (self: let
    callLibs = file:
      import file {
        inherit lib;
        nomics = self;
      };
  in {
    trivial = callLibs ./trivial.nix;

    inherit (self.trivial) version;
    inherit nixpkgs;
  });
}
