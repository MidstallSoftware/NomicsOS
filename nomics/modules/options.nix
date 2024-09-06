{
  config,
  lib,
  options,
  ...
}:
{
  options.nomics.options.pages = lib.mkOption {
    description = "List of pages for the Nomics Web Client";
    internal = true;
    type =
      with lib.types;
      listOf (submodule {
        options = {
          displayName = lib.mkOption {
            type = nullOr str;
            description = "Display name";
            default = null;
          };
          id = lib.mkOption {
            type = str;
            description = "Page ID";
          };
        };
      });
  };

  config = {
    nomics.options.pages = lib.mkBefore [
      {
        id = "general";
        displayName = "General";
      }
    ];

    system.build = {
      nomics-option-pages = builtins.toFile "nomics-option-pages.json" (
        builtins.toJSON config.nomics.options.pages
      );

      nomics-options =
        let
          optionAttrSetToDocList = optionAttrSetToDocList' [ ];

          optionAttrSetToDocList' =
            _: options:
            lib.concatMap (
              opt:
              let
                name = lib.showOption opt.loc;
                docOption =
                  {
                    loc = opt.loc;
                    inherit name;
                    description = opt.description or null;
                    declarations = lib.filter (x: x != lib.unknownModule) opt.declarations;
                    internal = opt.internal or false;
                    visible = if (opt ? visible && opt.visible == "shallow") then true else opt.visible or true;
                    readOnly = opt.readOnly or false;
                    type = opt.type.description or "unspecified";
                    label = opt.label or docOption.description;
                    pageId = opt.pageId or null;
                    isToplevel = opt.isToplevel or true;
                    childOf = opt.childOf or null;
                  }
                  // lib.optionalAttrs (opt ? example) {
                    example = builtins.addErrorContext "while evaluating the example of option `${name}`" (
                      lib.options.renderOptionValue opt.example
                    );
                  }
                  // lib.optionalAttrs (opt ? defaultText || opt ? default) {
                    default = builtins.addErrorContext "while evaluating the ${
                      if opt ? defaultText then "defaultText" else "default value"
                    } of option `${name}`" (lib.options.renderOptionValue (opt.defaultText or opt.default));
                  }
                  // lib.optionalAttrs (opt ? relatedPackages && opt.relatedPackages != null) {
                    inherit (opt) relatedPackages;
                  };

                subOptions =
                  let
                    ss = opt.type.getSubOptions opt.loc;
                  in
                  if ss != { } then
                    lib.map (
                      opt:
                      opt
                      // {
                        pageId = if (opt.pageId == null) then docOption.pageId else opt.pageId;
                        childOf = if (opt.childOf == null) then docOption.name else opt.childOf;
                        isToplevel = false;
                      }
                    ) (optionAttrSetToDocList' opt.loc ss)
                  else
                    [ ];
                subOptionsVisible = docOption.visible && opt.visible or null != "shallow";
              in
              # To find infinite recursion in NixOS option docs:
              # builtins.trace opt.loc
              [ docOption ] ++ lib.optionals subOptionsVisible subOptions
            ) (lib.collect lib.isOption options);

          rawOpts = optionAttrSetToDocList {
            nomics = options.nomics // {
              hostname = options.networking.hostName // {
                loc = [
                  "nomics"
                  "hostname"
                ];
              };
              storage = options.disko.devices // {
                loc = [
                  "nomics"
                  "storage"
                ];
              };
            };
          };
          filteredOpts = lib.filter (opt: opt.visible && !opt.internal) rawOpts;
          optionsList = lib.flip map filteredOpts (
            opt:
            opt
            // lib.optionalAttrs (opt ? relatedPackages && opt.relatedPackages != [ ]) {
              relatedPackages = genRelatedPackages opt.relatedPackages opt.name;
            }
          );

          genRelatedPackages =
            packages: optName:
            let
              unpack =
                p:
                if lib.isString p then
                  { name = p; }
                else if lib.isList p then
                  { path = p; }
                else
                  p;
              describe =
                args:
                let
                  title = args.title or null;
                  name = args.name or (lib.concatStringsSep "." args.path);
                in
                ''
                  - [${lib.optionalString (title != null) "${title} aka "}`pkgs.${name}`](
                      https://search.nixos.org/packages?show=${name}&sort=relevance&query=${name}
                    )${lib.optionalString (args ? comment) "\n\n  ${args.comment}"}
                '';
            in
            lib.concatMapStrings (p: describe (unpack p)) packages;

          optionsNix = builtins.listToAttrs (
            map (o: {
              name = o.name;
              value = removeAttrs o [
                "name"
                "visible"
                "internal"
              ];
            }) optionsList
          );
        in
        builtins.toFile "nomics-options.json" (
          builtins.unsafeDiscardStringContext (builtins.toJSON optionsNix)
        );
    };
  };
}
