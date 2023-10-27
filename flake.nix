{
  description = "ocaml module for flake-parts";
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
  };
  outputs = { self, opam-nix, ... }: {
    flakeModule = {
      imports = [ ./module.nix ];
      config = {
        perSystem.ocaml.inputs.opam-nix = opam-nix;
      };
    };
  };
}
