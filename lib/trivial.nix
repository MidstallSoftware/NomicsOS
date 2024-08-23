{
  lib,
  nomics,
}:
let
  trivial = {
    version = trivial.release + trivial.versionSuffix;
    release = lib.strings.fileContents ./.version;

    versionSuffix =
      let
        suffixFile = ../.version-suffix;
      in
      if lib.pathExists suffixFile then lib.strings.fileContents suffixFile else "pre-git";

    revisionWithDefault =
      default:
      let
        revisionFile = "${toString ./..}/.git-revision";
        gitRepo = "${toString ./..}/.git";
      in
      if lib.pathIsGitRepo gitRepo then
        lib.commitIdFromGitRepo gitRepo
      else if lib.pathExists revisionFile then
        lib.fileContents revisionFile
      else
        default;
  };
in
trivial
