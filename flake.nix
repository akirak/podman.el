{
  description = "An Emacs frontend to podman";

  inputs = {
    melpa = {
      url = "github:akirak/melpa/podman";
      flake = false;
    };

    nomake = {
      url = "github:akirak/nomake";
      inputs.melpa.follows = "melpa";
    };
  };

  outputs =
    { self
    , nomake
    , ...
    } @ inputs:
    nomake.lib.mkFlake {
      src = ./.;
      localPackages = [
        "podman"
      ];
 
      github.lint = {
        compile = true;
      };
   };
}
