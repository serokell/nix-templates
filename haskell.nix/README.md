Haskell application and library templates for Buildkite, Gitlab or GitHub CI using haskell.nix.
## How to use these templates

- The recommended way to use these templates (if you have nix flakes enabled): `nix flake init -t github:serokell/templates#haskell-application` for application or `nix flake init -t github:serokell/templates#haskell-library` for library.

- Otherwise:
    1. Copy `flake.nix` file to your repository, it contains all nix dependencies and definitions.

    2. Copy `default.nix` and `shell.nix` files which provide compatibility with non-flake nix interface.

    3. Get nix with `nix-command flakes` experimental features enabled, and run `nix flake update` to generate `flake.lock` file. This file pins the latest versions of the nix dependencies.

    4. Copy pipeline configuration: `.gitlab-ci.yml` for Gitlab, `.buildkite/pipeline.yml` for Buildkite or `.github/workflows/check.yml` for GitHub.

- Afterwards, adjust the template for your project:

    1.
       - **FOR APPLICATION:** Replace `pataq-package` in `flake.nix` with your haskell package name (usually specified in `package.yaml`). And replace `pataq-test` at the bottom of `flake.nix` with the name of the test component in your package.
       - **FOR LIBRARY:** Replace `pataq-package` in `flake.nix` with your haskell library name (usually specified in `package.yaml`). Then list the GHC versions that will be used to build and test your library in the [`tested-with`](https://cabal.readthedocs.io/en/3.4/cabal-package.html#pkg-field-tested-with) stanza of the `.cabal` file and change `./pataq-package.cabal` in `ghc-versions` in `flake.nix` to the path to your `.cabal` file. If you are using GitHub actions, uncomment `ghc-matrix` in `flake.nix`, otherwise change `matrix` in the CI pipeline to the list of GHC versions specified in `ghc-versions`.
    If your project contains multiple packages, you need to make the following changes to `flake.nix`:
            * Replace `hs-package-name` with a list of package names (note the "s" at the end of the attribute name):
            ```nix
            hs-package-names = [ "first-package-name" "second-package-name" ];
            ```
            * Update `modules`, `build-all`, and `test-all` to map over all packages as follows:

            ```nix
            modules = map (hs-package-name: {
              packages.${hs-package-name} = {
                ghcOptions = [
                  "-Werror"
                  "-O0"
                ];
              };
            }) hs-package-names;
            ```

            ```nix
            build-all = lib.mapAttrs'
              (ghc: pkg:
                let components = lib.concatMap (hs-package-name:
                  get-package-components pkg.${hs-package-name}.components) hs-package-names;
                in lib.nameValuePair "${ghc}:build-all"
                  (pkgs.linkFarmFromDrvs "build-all" components)) pkgs-per-ghc;
            ```

            ```nix
            test-all = lib.mapAttrs'
              (ghc: pkg:
                let tests = lib.concatMap (hs-package-name: lib.filter lib.isDerivation
                  (lib.attrValues pkg.${hs-package-name}.checks)) hs-package-names;
                in lib.nameValuePair "${ghc}:test-all"
                  (pkgs.linkFarmFromDrvs "test-all" tests)) pkgs-per-ghc;
            ```

    2. If your project contains bash scripts, uncomment related lines in `flake.nix` and in the pipeline configuration. If you don't need `shellcheck`, remove those lines.

- Enjoy working CI!
