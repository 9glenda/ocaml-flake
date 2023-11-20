# ocaml-flake

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/9glenda/ocaml-flake/badge)](https://flakehub.com/flake/9glenda/ocaml-flake)

> \[!IMPORTANT\]
>
> This project is work in progress and the api may change.

Simple [flake parts](https://github.com/hercules-ci/flake-parts) module for ocaml inspired by [haskell-flake](https://github.com/srid/haskell-flake) using [opam nix](https://github.com/tweag/opam-nix).

## Getting Started

```nix
{
  description = "Ocaml project using `ocaml-flake` and `flake-parts`";

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
    };
}
```

## Thanks to

- [haskell-flake](https://github.com/srid/haskell-flake): One of the biggest inspirations for starting this project and designing the interface was the haskell flake. It is a great `flake-parts` module for haskell and my reccomendation for everyone starting a new haskell project.
- [flake parts](https://github.com/hercules-ci/flake-parts): Obviously this project would not been possible without `flake-parts`. It's a growing ecosystem around designing clean and maintainable flakes.
- [opam-nix](https://github.com/tweag/opam-nix): opam-nix is used to build the package internally.
