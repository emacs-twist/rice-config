{
  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    emacs-ci.url = "github:purcell/nix-emacs-ci";
    twist.url = "github:emacs-twist/twist.nix";
    rice-src.url = "github:emacs-twist/rice-config?dir=example";
    # See https://github.com/NixOS/nix/issues/9339
    rice-lock.url = "github:emacs-twist/rice-config?dir=lock";
    emacs-builtins.url = "github:emacs-twist/emacs-builtins";
    emacs-builtins.inputs = {
      # This reduces the number of entries in flake.lock but functionally has no
      # effect.
      emacs-ci.follows = "emacs-ci";
      twist.follows = "twist";
    };
    melpa.url = "github:melpa/melpa";
    melpa.flake = false;
  };

  nixConfig = {
    extra-substituters = "https://emacs-ci.cachix.org";
    extra-trusted-public-keys = "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4=";
  };

  outputs = {
    flake-parts,
    systems,
    nixpkgs,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
        (
          {flake-parts-lib, ...}:
            flake-parts-lib.importApply ./module.nix {
              inherit (inputs) emacs-builtins;
            }
        )
      ];

      elisp-rice = {
        localPackages = inputs.rice-src.elisp-rice.packages;
        src = inputs.rice-src.outPath;
        melpa = inputs.melpa.outPath;
        lockDir = inputs.rice-lock.outPath;
        lockInputName = "rice-lock";
      };

      perSystem = {
        system,
        config,
        pkgs,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.twist.overlays.default
          ];
        };

        elisp-rice = {
          emacsPackageSet = inputs.emacs-ci.packages.${system};
          defaultEmacsPackage = inputs.emacs-ci.packages.emacs-snapshot;
        };

        devShells.default = config.pre-commit.devShell;

        # elisp-byte-compile runs a local version of Emacs, which is available
        # in the Nix sandbox
        pre-commit.check.enable = false;
        pre-commit.settings.excludes = ["^lock/"];

        # pre-commit checks for non-elisp files
        pre-commit.settings.hooks.actionlint.enable = true;
        pre-commit.settings.hooks.alejandra.enable = true;
        pre-commit.settings.hooks.deadnix.enable = true;
        pre-commit.settings.hooks.nil.enable = true;
        # statix is slow, so I won't use it.

        # pre-commit checks for elisp files
        pre-commit.settings.hooks.elisp-byte-compile.enable = true;
        pre-commit.settings.hooks.elisp-byte-compile.stages = ["push"];
      };
    };
}
