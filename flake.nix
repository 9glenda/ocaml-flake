{
  description = "ocaml module for flake-parts";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    call-flake.url = "github:divnix/call-flake";
    haumea = {
      url = "github:nix-community/haumea";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    namaka = {
      url = "github:nix-community/namaka";
      inputs = {
        haumea.follows = "haumea";
        nixpkgs.follows = "nixpkgs";
      };
    };
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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    opam-nix,
    flake-parts,
    treefmt-nix,
    namaka,
    ...
  }: let
    flakeModule = {
      imports = [./flake-module.nix];
      config = {
        perSystem.ocaml.inputs = {
          inherit opam-nix;
          inherit (inputs) opam-repository;
          treefmt = treefmt-nix;
        };
      };
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        # flakeModule
        treefmt-nix.flakeModule
        # flake-root.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        treefmt = import ./treefmt.nix;
        devShells = {
          default = pkgs.mkShell {
            packages = [
              namaka.packages.${system}.default
              pkgs.mdbook
            ];
          };
        };
      };
      flake = let
        mkTemplate = path:
          builtins.path {
            inherit path;
            filter = name: _t: baseNameOf name != "flake.lock";
          };
      in {
        inherit flakeModule;
        templates = {
          simple = {
            path = mkTemplate ./examples/simple;
            description = "Simple dune project";
            welcomeText = ''
              You just created an ocaml-flake template. Read more about it here:
              https://github.com/9glenda/ocaml-flake/tree/main/docs
            '';
          };
        };
      };
    };
}
