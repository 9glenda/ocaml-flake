{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ocaml-flake.url = "github:9glenda/ocaml-flake";
  };

  outputs = inputs @ {
    flake-parts,
    ocaml-flake,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ocaml-flake.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = _: {
        ocaml = {
          duneProjects = {
            default = {
              name = "my_package";
              src = ./.;
            };
          };
        };
      };
      flake = {
      };
    };
}
