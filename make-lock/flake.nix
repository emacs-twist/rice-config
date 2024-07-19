{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    elisp-rice.url = "github:emacs-twist/elisp-rice";

    systems.url = "github:nix-systems/default";

    emacs-ci.url = "github:purcell/nix-emacs-ci";
    twist.url = "github:emacs-twist/twist.nix";

    # Inputs that should be overridden for each project.
    rice-src.url = "github:emacs-twist/rice-config?dir=example";
    # If your project depends only on built-in packages, you don't have to
    # override this. Also see https://github.com/NixOS/nix/issues/9339
    rice-lock.url = "github:emacs-twist/rice-config?dir=lock";

    emacs-builtins.url = "github:emacs-twist/emacs-builtins";

    registries.url = "github:emacs-twist/registries";
    registries.inputs.melpa.follows = "melpa";

    melpa.url = "github:melpa/melpa";
    melpa.flake = false;
  };

  # Use the binary cache of emacs-ci executables.
  nixConfig = {
    extra-substituters = "https://emacs-ci.cachix.org";
    extra-trusted-public-keys = "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4=";
  };

  outputs = {
    nixpkgs,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} ({flake-parts-lib, ...}: let
      systems = import inputs.systems;
    in {
      inherit systems;
      imports = [
        inputs.elisp-rice.flakeModules.default
      ];
      elisp-rice = inputs.elisp-rice.lib.configFromInputs {
        inherit (inputs) rice-src rice-lock registries systems;
      };
      perSystem = {
        system,
        config,
        pkgs,
        ...
      }: {
        # Configure the perSystem environment.
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # This overlay is required to make `emacsTwist` function available
            # in the flake-parts module.
            inputs.twist.overlays.default
          ];
        };

        # Configure the per-system Emacs package set.
        elisp-rice = {
          # Disable the packages until the lock directory is available.
          enableElispPackages = false;
          emacsPackageSet = inputs.emacs-ci.packages.${system};
        };
      };
    });
}
