Template for haskell.nix configuration for Buildkite or Gitlab CI

## How to use this template

1. Copy `flake.nix` file to you repository, it contains all nix dependencies and definitions. Or you can use `nix flake` to copy the whole template: `nix flake init -t github:serokell/templates#haskell-nix`.

2. Copy `default.nix` and `shell.nix` files which provide compatibility with non-flake nix interface.

3. Copy pipeline configuration: `.gitlab-ci.yml` for Gitlab, or `.buildkite/pipeline.yml` for Buildkite.

4. Replace `pataq-package` in `flake.nix` with your haskell package name (usually specified in `package.yaml`). And replace `pataq-test` at the bottom of `flake.nix` with the name of the test component in your package.

5. If you want to run weeder or hlint in your CI, uncomment related lines in `flake.nix` and in the pipeline configuration. If you don't need weeder or hlint, remove those lines.

6. Get unstable nix with `nix-command flakes` experimental features enabled, and run `nix flake update` to generate `flake.lock` file. This file pins latest versions of the nix dependencies.

7. Enjoy working CI.
