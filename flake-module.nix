# Largely inspired by:
# https://github.com/srid/proc-flake/blob/master/flake-module.nix
{
  config,
  lib,
  flake-parts-lib,
  ...
} @ args: let
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;
  inherit
    (lib)
    types
    ;

  inputs = args.config.ocaml-nix._inputs;
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
              description = lib.mdDoc ''
                dune Projects.
              '';
            };
            inputs = {
              opam-nix = lib.mkOption {
                type = types.raw;
                description = lib.mdDoc ''
                  opam-nix flake input
                '';
              };
            };
          };
        };
        duneProjectSubmodule = types.submodule ({name, ...}: let
          attrName = name;
        in {
          options = {
            name = lib.mkOption {
              type = types.str;
              description = lib.mdDoc ''
                name of the dune package. Defined in dune-project
              '';
              default = "${attrName}";
            };
            src = lib.mkOption {
              type = types.path;
              description = lib.mdDoc ''
                name of the dune package. Defined in dune-project
              '';
            };
            settings = let
              packageName = name;
            in {
              devPackages = lib.mkOption {
                type = types.attrsOf types.str;
                description = lib.mdDoc ''
                  development packages like the lsp and ocamlformat.
                  Those packages get installed in the dev shell too.
                '';
                default = {
                  ocaml-lsp-server = "1.16.2";
                  ocamlformat = "0.26.1";
                  utop = "2.13.1";
                  ocamlfind = "1.9.6";
                };
              };
              overlay = lib.mkOption {
                type = types.raw;
                default = _final: prev: {
                  ${packageName} = prev.${packageName}.overrideAttrs (_: {
                    doNixSupport = false;
                  });
                };
              };
              extraDevPackages = lib.mkOption {
                type = types.listOf types.package;
                description = lib.mdDoc "Extra packages to install";
                default = [];
              };
              query = lib.mkOption {
                type = types.attrsOf types.str;
                description = lib.mdDoc ''
                  opam packages like the base compiler
                '';
                default = {
                  ocaml-base-compiler = "5.1.0";
                };
              };
            };
          };
        });
      in {
        options.ocaml = lib.mkOption {
          type = ocamlSubmodule;
          description = lib.mdDoc ''
            Ocaml module
          '';
          default = {};
        };
        config = let
          mkScopedProject = name: value: rec {
            package = value.name;
            inherit (config.ocaml.inputs) opam-nix;
            opam-nixLib = opam-nix.lib.${system};
            devPackagesQuery = value.settings.devPackages;
            query = devPackagesQuery // value.settings.query;
            scope = opam-nixLib.buildDuneProject {} "${package}" value.src query;
            inherit (value.settings) overlay;
            scope' = scope.overrideScope' overlay;
            main = scope'.${package};
            devPackages =
              builtins.attrValues
              (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope')
              ++ value.settings.extraDevPackages;
          };
        in {
          packages = builtins.mapAttrs (name: value: let
            scoped = mkScopedProject name value;
          in
            scoped.main)
          config.ocaml.duneProjects;

          devShells = builtins.mapAttrs (name: value: let
            scoped = mkScopedProject name value;
            inherit (scoped) main devPackages;
          in
            pkgs.mkShell {
              inputsFrom = [main];
              buildInputs = devPackages;
            })
          config.ocaml.duneProjects;
        };
      });
  };
}
