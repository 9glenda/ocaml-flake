# Largely inspired by:
# https://github.com/srid/proc-flake/blob/master/flake-module.nix
{
  lib,
  flake-parts-lib,
  ...
}: let
  evalOptional = {
    condition,
    value,
    default,
  }:
    if condition
    then value
    else default;
  # evalNonNull = { value, default }: evalOptional { condition = (value != null); inherit value default; };
  # evalNonNullAttr = value: evalOptional { condition = (value != null); inherit value; default = {}; };
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;
  inherit
    (lib)
    types
    ;
in {
  options = {
    perSystem =
      mkPerSystemOption
      ({
        config,
        pkgs,
        system,
        ...
      }: let
        ocamlSubmodule = types.submodule {
          options = {
            duneProjects = lib.mkOption {
              type = types.attrsOf duneProjectSubmodule;
              description = lib.literalMD ''
                dune Projects.
              '';
              default = {};
            };
            inputs = {
              treefmt = lib.mkOption {
                type = types.raw;
                description = lib.literalMD ''
                  treefmt flake input
                '';
              };
              opam-nix = lib.mkOption {
                type = types.raw;
                description = lib.literalMD ''
                  opam-nix flake input
                '';
              };
            };
          };
        };
        duneProjectSubmodule = types.submodule (args @ {name, ...}: let
          # name is shadowed by the name option
          attrName = name;
        in {
          options = {
            # most settings are in settings or deveShell to keep the toplevel settings clean
            name = lib.mkOption {
              type = types.str;
              description = lib.literalMD ''
                name of the dune package. Defined in dune-project
              '';
              default = "${attrName}";
            };
            src = lib.mkOption {
              type = types.path;
              description = lib.literalMD ''
                name of the dune package. Defined in dune-project
              '';
              # example = ./.;
            };
            autoWire = let
              autoWireOutputs = lib.attrNames args.config.outputs;
            in
              lib.mkOption {
                type = types.listOf (types.enum autoWireOutputs);
                description = lib.literalMD ''
                  What will be added to the flake outputs.

                  Note for dev shells nix will create a dev shell from the default package in case no dev shell is specified.
                '';
                default = ["devShell" "package"];
                # example = autoWireOutputs;
              };

            # the outputs are stored here and later mapped in the global perSystem scope
            # all outputs stored in outputs must use autoWire.
            outputs = {
              package = lib.mkOption {
                type = types.nullOr types.package;
                readOnly = true;
              };
              devShell = lib.mkOption {
                type = types.nullOr types.raw;
                readOnly = true;
              };
            };

            devShell = {
              enable = lib.mkOption {
                type = types.bool;
                description = lib.literalMD ''
                  Create a dev shell for the project.
                  The devShell is located in `ocaml.dunePackage.<name>.outputs.devShell`.
                  To automatically add the dev shell to the outputs of the flake add `"devshell"` to `autoWire`.
                '';
                default = true;
              };
              name = lib.mkOption {
                type = types.str;
                description = lib.literalMD ''
                  name of the devShell
                '';
                default = "${attrName} development development shell";
              };
              inputsFromPackage = lib.mkOption {
                type = types.bool;
                description = lib.literalMD ''
                  Take inputs from the package.
                '';
                default = true;
                # example = false;
              };
              extraPackages = lib.mkOption {
                type = types.listOf types.package;
                description = lib.literalMD ''
                  Extra packages to install into the dev shell alongside the `opamPackages`.
                '';
                default = [];
                # example = with pkgs; [mdbook];
              };
              mkShellArgs = lib.mkOption {
                type = types.attrsOf types.raw;
                description = lib.literalMD ''
                  Extra arguments to pass to `pkgs.mkShell`.

                  The already set arguments get overwritten. It's implemented like this:
                  ```nix
                    pkgs.mkShell ({ ... } // mkShellArgs)
                  ```
                '';
                default = {};
                # example = ''
                # {
                #   shellHook = \'\'
                #     echo "example shell hook"
                #   \'\';
                # };
                # '';
              };

              opamPackages = lib.mkOption {
                type = types.attrsOf types.str;
                description = lib.literalMD ''
                  development packages like the lsp and ocamlformat.
                  Those packages get installed in the dev shell too.
                  If the devShell is disabled this option will be ignored.
                '';
                default = {
                  ocaml-lsp-server = "1.16.2";
                  ocamlformat = "0.26.1";
                  utop = "2.13.1";
                  ocamlfind = "1.9.6";
                };
                # example = {
                # ocaml-lsp-server = "*";
                # utop = "*";
                # };
              };
            };

            settings = {
              overlay = lib.mkOption {
                type = types.raw;
                description = lib.literalMD ''
                  overlay applied to opam-nix
                '';
                default = _: _: {
                };
                # example = _final: prev: {
                # ${name} = prev.${name}.overrideAttrs (_: {
                #   doNixSupport = false;
                # });
                # };
              };
              opamPackages = lib.mkOption {
                type = types.attrsOf types.str;
                description = lib.literalMD ''
                  opam packages like the base compiler
                '';
                default = {
                  ocaml-base-compiler = "5.1.0";
                };
              };
            };
          };
          config = let
            inherit (config.ocaml.inputs) opam-nix;

            opam-nixLib = opam-nix.lib.${system};

            devPackagesQuery = evalOptional {
              condition = args.config.devShell.enable;
              value = args.config.devShell.opamPackages;
              default = {};
            };
            query = devPackagesQuery // args.config.settings.opamPackages;

            scope =
              opam-nixLib.buildDuneProject {} "${args.config.name}" args.config.src query;
            scope' = scope.overrideScope' args.config.settings.overlay;

            main = scope'.${args.config.name};

            devPackages =
              builtins.attrValues
              (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope')
              ++ args.config.devShell.extraPackages;
          in {
            outputs = {
              package = main;
              devShell = evalOptional {
                condition = args.config.devShell.enable;
                value = pkgs.mkShell ({
                    # TODO: extra inputs from? or should this be done through overriding?
                    inputsFrom =
                      if args.config.devShell.inputsFromPackage
                      then [main]
                      else [];
                    buildInputs = devPackages;
                  }
                  // args.config.devShell.mkShellArgs);
                default = null;
              };
            };
          };
        });
      in {
        options.ocaml = lib.mkOption {
          type = ocamlSubmodule;
          description = lib.literalMD ''
            Ocaml module
          '';
          default = {};
        };

        config = let
          inherit (config.ocaml) duneProjects;
          filterProjects = duneProjects: f: lib.filterAttrs (n: v: f n v) duneProjects;
          # example outputName `"package"`
          mapOutputs = duneProjects: f: f': builtins.mapAttrs (name: value: f name value) (filterProjects duneProjects f');
          mapOutputsAutoWire = duneProjects: outputName: mapOutputs duneProjects (_name: value: value.outputs.${outputName}) (_n: v: (builtins.elem "${outputName}" v.autoWire && v.outputs.${outputName} != null));
          # autoWire :: types.listOf types.enum [ ... ]
          # therefore all all the autputs supported by autoWire as a list .
          # autoWireMap = autoWire: f: lib.mapListToAttrs (item: lib.nameValuePair "${item}s" (f item)) autoWire;
          # autoWireMap' = autoWire: duneProjects: autoWireMap autoWire mapOutputs duneProjects;
        in {
          packages = mapOutputsAutoWire duneProjects "package";
          devShells = mapOutputsAutoWire duneProjects "devShell";
        };
        # config = let
        #   dunePkgs = config.ocaml.duneProjects;
        # in
        #   if (dunePkgs != {})
        #   then let
        #     mkScopedProject = _name: value: rec {
        #       inherit (config.ocaml.inputs) opam-nix;
        #       inherit (value.settings) overlay;
        #       inherit (value) name;
        #       opam-nixLib = opam-nix.lib.${system};
        #       devPackagesQuery = value.settings.devPackages;
        #       query = devPackagesQuery // value.settings.packages;
        #       scope =
        #         opam-nixLib.buildDuneProject {} "${name}" value.src query;
        #       scope' = scope.overrideScope' overlay;
        #       main = scope'.${name};
        #       devPackages =
        #         builtins.attrValues
        #         (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope')
        #         ++ value.settings.extraDevPackages;
        #     };
        #   in {
        #     packages = builtins.mapAttrs (name: value: let
        #       scoped = mkScopedProject name value;
        #     in
        #       scoped.main)
        #     dunePkgs;

        #     devShells = builtins.mapAttrs (name: value: let
        #       scoped = mkScopedProject name value;
        #       inherit (scoped) main devPackages;
        #     in
        #       pkgs.mkShell {
        #         inputsFrom = [main];
        #         buildInputs = devPackages;
        #       })
        #     dunePkgs;
        #   }
        #   else {};
      });
  };
}
