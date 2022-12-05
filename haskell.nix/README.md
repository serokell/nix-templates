Template for haskell.nix configuration for Buildkite, Gitlab or GitHub CI

## How to use this template

- The recommended way to use this template (if you have nix flakes enabled) is `nix flake init -t github:serokell/templates#haskell-nix`

- Otherwise:
    1. Copy `flake.nix` file to you repository, it contains all nix dependencies and definitions.

    2. Copy `default.nix` and `shell.nix` files which provide compatibility with non-flake nix interface.

    3. Get unstable nix with `nix-command flakes` experimental features enabled, and run `nix flake update` to generate `flake.lock` file. This file pins the latest versions of the nix dependencies.

    4. Copy pipeline configuration: `.gitlab-ci.yml` for Gitlab, `.buildkite/pipeline.yml` for Buildkite or `.github/workflows/check.yml` for GitHub.

- Afterwards, adjust the template for your project:

    1. Replace `pataq-package` in `flake.nix` with your haskell package name (usually specified in `package.yaml`). And replace `pataq-test` at the bottom of `flake.nix` with the name of the test component in your package.

    2. If you want to run weeder or hlint in your CI, uncomment related lines in `flake.nix` and in the pipeline configuration. If you don't need weeder or hlint, remove those lines.

- Enjoy working CI!
