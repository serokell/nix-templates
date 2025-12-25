# Generic Nix flake tempate

The recommended way to use this templates (if you have nix flakes enabled):
```
nix flake init -t github:serokell/templates#generic
```

Note that this command will likely conflict with the existing `flake.nix` in the repository,
so it's recommended to move files from this template manually if your project already has Nix-flake setup.

## Content
* [`flake.nix`](./flake.nix) - Nix flake with generic checks that can be used by CI pipeline
* [`.gitlab-ci.yml`](./.gitlab-ci.yml) - template for GitLab CI pipeline.
* [`.github/workflows/check.yml`](./.github/workflows/check.yml) - template for GitHub Actions pipeline.
