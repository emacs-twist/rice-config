{
  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";

    elisp-rice.url = "github:emacs-twist/elisp-rice";

    # Dependencies of rice itself and this rice configuration.
    emacs-ci.url = "github:purcell/nix-emacs-ci";
    twist.url = "github:emacs-twist/twist.nix";

    # Inputs that should be overridden for each project.
    rice-src.url = "github:emacs-twist/rice-config?dir=example";
    # If your project depends only on built-in packages, you don't have to
    # override this. Also see https://github.com/NixOS/nix/issues/9339
    rice-lock.url = "github:emacs-twist/rice-config?dir=lock";

    # Inputs that can be customized depending on your project.
    melpa.url = "github:melpa/melpa";
    melpa.flake = false;

    # Optional dependencies of this flake.
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  # Use the binary cache of emacs-ci executables.
  nixConfig = {
    extra-substituters = "https://emacs-ci.cachix.org";
    extra-trusted-public-keys = "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4=";
  };

  outputs = {
    flake-parts,
    nixpkgs,
    ...
  } @ inputs: let
    systems = import inputs.systems;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      inherit systems;
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.elisp-rice.flakeModules.default
      ];

      # Configure the Emacs environment in Nix.
      elisp-rice = {
        localPackages = inputs.rice-src.elisp-rice.packages;
        src = inputs.rice-src.outPath;
        melpa = inputs.melpa.outPath;
        lockDir = inputs.rice-lock.outPath;
        lockInputName = "rice-lock";
        github = {
          inherit systems;
        };
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
          emacsPackageSet = inputs.emacs-ci.packages.${system};
          defaultEmacsPackage = inputs.emacs-ci.packages.${system}.emacs-snapshot;
        };

        # Enable pre-commit by entering the Nix devShell.
        devShells.default = config.pre-commit.devShell;

        # elisp-byte-compile runs a local version of Emacs, which is available
        # in the Nix sandbox. You must disable this check to enable the
        # byte-compile hook.
        pre-commit.check.enable = false;
        pre-commit.settings.excludes = ["^lock/"];

        # pre-commit checks for non-elisp files (optional)
        pre-commit.settings.hooks.actionlint.enable = true;
        pre-commit.settings.hooks.alejandra.enable = true;
        pre-commit.settings.hooks.deadnix.enable = true;

        # pre-commit checks for elisp files
        pre-commit.settings.hooks.elisp-byte-compile.enable = true;
        # You can run byte-compile only in pre-commit.
        pre-commit.settings.hooks.elisp-byte-compile.stages = ["push"];
      };
    };
}
