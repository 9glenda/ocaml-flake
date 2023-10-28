{
  description = "ocaml module for flake-parts";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs.opam-repository.follows = "opam-repository";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.opam2json.follows = "opam2json";
      inputs.opam-overlays.follows = "opam-overlays";
      inputs.mirage-opam-overlays.follows = "mirage-opam-overlays";
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
  };
  outputs = inputs @ {
    opam-nix,
    flake-parts,
    treefmt-nix,
    ...
  }: let
    flakeModule = {
      imports = [./flake-module.nix];
      config = {
        perSystem.ocaml.inputs = {
          opam-nix = opam-nix;
          treefmt = treefmt-nix;
        };
      };
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        # flakeModule
        # treefmt-nix.flakeModule
        # inputs.flake-root.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        config,
        flake-root,
        ...
      }: {
        # flake-root.projectRootFile = "flake.nix";
        # treefmt = import ./treefmt.nix;
          # // {
          #   inherit (config.flake-root) projectRootFile;
          # };
      };
      flake = {
        inherit flakeModule;
        # templates = {
        #   simple = {
        #     path = ./examples/simple;
        #     description = "Simple dune project";
        #     welcomeText = ''
        #       You just created an ocaml-flake template. Read more about it here:
        #       https://github.com/9glenda/ocaml-flake/tree/main/docs
        #     '';
        #   };
        # };
      };
    };
}
