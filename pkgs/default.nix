{ lib, outPath }:
pkgs: prev: with pkgs; {
  dart = prev.dart.override rec {
    version = "3.5.1";
    sources = {
      "${version}-x86_64-darwin" = fetchurl {
        url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${version}/sdk/dartsdk-macos-x64-release.zip";
        sha256 = "18v73dr61033g0x27vb0fdjwyzc1d04fifmwwnv4157nfpb68ijc";
      };
      "${version}-aarch64-darwin" = fetchurl {
        url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${version}/sdk/dartsdk-macos-arm64-release.zip";
        sha256 = "1vjsnwlkvsb0xvap45fdd81vdsjkpl2yxr8xh39v77dxbpybi0qh";
      };
      "${version}-aarch64-linux" = fetchurl {
        url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${version}/sdk/dartsdk-linux-arm64-release.zip";
        sha256 = "0lwnvky3p37d81ib6qwxra7lxn19l5x30c7aycixd9yaslq1bc0v";
      };
      "${version}-x86_64-linux" = fetchurl {
        url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${version}/sdk/dartsdk-linux-x64-release.zip";
        sha256 = "0zn2mw8awii0hrvyh146hb5604li0jgxxgavpi19zcdpnzdg6z7c";
      };
      "${version}-i686-linux" = fetchurl {
        url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${version}/sdk/dartsdk-linux-ia32-release.zip";
        sha256 = "11x7yyif51hyn8yi2lqbkfm3lfalkvh54v5pi851mfdnf14hsjpw";
      };
    };
  };

  nomics = lib.makeScope newScope (
    self:
    {
      inherit (lib.nomics) version;
      path = lib.cleanSourceWith {
        filter = name: type: lib.hasPrefix "${outPath}/pkgs" name && name != "${outPath}/pkgs/default.nix";
        src = outPath;
      };

      __packages = lib.attrNames (
        lib.filterAttrs (name: value: lib.isAttrs value && value ? default && value ? devShell) (
          lib.removeAttrs self [ "__packages" ]
        )
      );
    }
    // lib.genAttrs [ "web-client" ] (pkg: {
      default = self.callPackage ./${pkg} { };
      devShell = self.callPackage ./${pkg}/shell.nix { };
    })
  );
}
