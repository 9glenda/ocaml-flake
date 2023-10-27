{
  description = "ocaml module for flake-parts";
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
  };
  outputs = { self, ... } @ inp: {
    flakeModule = {
      imports = [./module.nix];
      config = {
        ocaml-nix._inputs = {
          inherit (inp) opam-nix;
        };
      };
    };
  };
}
