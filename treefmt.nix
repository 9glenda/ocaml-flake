{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true; # nix
    statix.enable = true;
    deadnix.enable = true; # find dead nix code
  };
}
