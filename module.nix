# Largely inspired by:
# https://github.com/srid/proc-flake/blob/master/flake-module.nix
{ self, config, lib, flake-parts-lib, ... } @ args:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    types;

  inputs = args.config.ocaml-nix._inputs;
  inherit (inputs) opam-nix;
in
{
  options = {
    ocaml-nix._inputs = lib.mkOption {
      type = types.raw;
      internal = true;
    };
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }:
        let
          ocamlSubmodule = types.submodule {
            options = {
              packages = lib.mkOption {
                type = types.attrsOf projectSubmodule;
                description = lib.mdDoc ''
                '';
              };
              # opam-nix = types.mkOption {
              #   type = types.anything;
              # };
            };
          };
          projectSubmodule = types.submodule (args@{ name, ... }: {
            options = {
              name = lib.mkOption {
                type = types.str;
                description = lib.mdDoc ''
                  name of the dune package
                '';
              };
              pkg = lib.mkOption {
                type = types.package;
                description = lib.mdDoc ''
                  list of packages to put into the module
                '';
              };
              devPackages = lib.mkOption {
                type = types.attrsOf types.str;
                description = lib.mdDoc ''
                  development packages
                '';
              };
            };
            config =
              let 
                # on = opam-nix.lib.${system};
              in
              {
                pkg = pkgs.hello;

              };
          });
        in
        {
          options.ocaml = lib.mkOption {
            type = ocamlSubmodule;
            description = lib.mdDoc ''
              Ocaml module
            '';
            default = { };
          };
          config = let 
          in {
            packages = builtins.mapAttrs (name: value: let 
              # oc' = oc value.name;
              package = value.name;
              # inherit (config.ocaml) opam-nix;
              on = opam-nix.lib.${system};
              devPackagesQuery = {
                ocaml-lsp-server = "1.16.2";
                ocamlformat = "0.26.1";
                utop = "2.13.1";
                ocamlfind = "1.9.6";
              };
              query = devPackagesQuery // {
                ocaml-base-compiler = "5.1.0";
              };
              scope = on.buildDuneProject { 
                 # inherit repos;
               } "${package}" ./. query;
               overlay = final: prev: {
                 # You can add overrides here
                 ${package} = prev.${package}.overrideAttrs (_: {
                   # Prevent the ocaml dependencies from leaking into dependent environments
                   doNixSupport = false;
                 });
               };
               scope' = scope.overrideScope' overlay;
               # The main package containing the executable
               main = scope'.${package};
               # Packages from devPackagesQuery
               devPackages = builtins.attrValues
                 (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');

              # inherit (oc') devPackagesQuery query scope overlay scope' main devPackages;
            in main
            ) config.ocaml.packages;
          };
        });
  };
}
