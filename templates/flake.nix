{
  outputs = {...}: {
    templates = {
      default = {
        path = ./default;
        description = "Default boilerplate that can be added to an existing Emacs Lisp project";
        welcomeText = ''
          Please adjust flake.nix, justfile and .github/workflows/check-emacs-lisp.yml
          to your project.
        '';
      };
    };
  };
}
