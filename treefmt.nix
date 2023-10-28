{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    statix.enable = true;
    deadnix.enable = true;
    yamlfmt.enable = true;
  };
}
