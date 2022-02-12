{
  description = "An Emacs frontend to podman";

  inputs = {
    melpa = {
      url = "github:akirak/melpa/podman";
      flake = false;
    };

    elinter = {
      url = "github:akirak/elinter/v5";
      inputs.melpa.follows = "melpa";
    };
  };

  outputs =
    { self
    , elinter
    , ...
    } @ inputs:
    elinter.lib.mkFlake {
      src = ./.;
      localPackages = [
        "podman"
      ];
    };
}
