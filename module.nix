# Largely inspired by:
# https://github.com/srid/proc-flake/blob/master/flake-module.nix
{ self, config, lib, flake-parts-lib, ... } @ args:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    types;

  inputs = args.config.ocaml-nix_inputs;
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
              pkgs = lib.mkOption {
                type = types.listOf types.pkgs;
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
                on = opam-nix.lib.${system};
              in
              {
                packages = {
                  "${name}" = pkgs.writeShellApplication {
                  inherit name;
                  text = ''
                      echo "${name}"
                    '';
                };
              };

              # devShell = pkgs.mkShell {
              #   nativeBuildInputs = with pkgs; [ ocaml ];
              # };

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
        });
  };
}
