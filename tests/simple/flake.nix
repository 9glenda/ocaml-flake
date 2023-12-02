{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs = {
        opam-repository.follows = "opam-repository";
        nixpkgs.follows = "nixpkgs";
        opam2json.follows = "opam2json";
        opam-overlays.follows = "opam-overlays";
        mirage-opam-overlays.follows = "mirage-opam-overlays";
      };
    };
    flake-root.url = "github:srid/flake-root";
    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };
    mirage-opam-overlays = {
      url = "github:dune-universe/mirage-opam-overlays";
      flake = false;
    };
    opam-overlays = {
      url = "github:dune-universe/opam-overlays";
      flake = false;
    };
    opam2json = {
      url = "github:tweag/opam2json";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ocaml-flake.url = "github:9glenda/ocaml-flake";
    # opam-nix = {
    #   url = "github:tweag/opam-nix";
    # };
    # treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {
    flake-parts,
    opam-nix,
    opam-repository,
    treefmt-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = let
        flakeModule = {
          imports = [./../../flake-module.nix];
          config = {
            perSystem.ocaml.inputs = {
              inherit opam-nix opam-repository;
              treefmt = treefmt-nix;
            };
          };
        };
      in [
        flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = _: {
        ocaml = {
          duneProjects = {
            default = {
              name = "my_package";
              src = ./.;
              autoWire = [
                "package"
              ];
            };
          };
        };
        # devShells = {};
      };
      flake = {
      };
    };
}
