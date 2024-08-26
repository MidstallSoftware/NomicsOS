{ config, lib, ... }:
let
  cfg = config.nomics.users;
in
{
  options.nomics.users = lib.mkOption {
    description = "List of users";
    type =
      with lib.types;
      listOf (submodule {
        options = {
          displayName = lib.mkOption {
            type = nullOr str;
            description = "Display name of user, defaults to user name";
            default = null;
          };
          name = lib.mkOption {
            type = str;
            description = "Name of user";
          };
          password = lib.mkOption {
            type = str;
            description = "Password of user";
          };
        };
      });
  };

  config.users.users = lib.listToAttrs (
    lib.map (
      {
        name,
        password,
        displayName,
      }:
      lib.nameValuePair name {
        description = lib.optionalString (displayName != null) displayName;
        isNormalUser = true;
        inherit password;
      }
    ) cfg
  );
}
