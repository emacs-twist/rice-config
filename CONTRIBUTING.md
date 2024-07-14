FIXME

To check the API locally, use the following command:

```sh
nix flake show --override-input rice-src "path:$PWD/example" --override-input rice-lock "path:$PWD/lock" --override-input melpa github:emacs-twist/melpa/hello-for-rice
```
