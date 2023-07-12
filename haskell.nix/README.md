Haskell application and library templates for Buildkite, Gitlab or GitHub CI using haskell.nix.
## How to use these templates

- The recommended way to use these templates (if you have nix flakes enabled): `nix flake init -t github:serokell/templates#haskell-application` for application or `nix flake init -t github:serokell/templates#haskell-library` for library.

- Otherwise:
    1. Copy `flake.nix` file to your repository, it contains all nix dependencies and definitions.

    2. Copy `default.nix` and `shell.nix` files which provide compatibility with non-flake nix interface.

    3. Get nix with `nix-command flakes` experimental features enabled, and run `nix flake update` to generate `flake.lock` file. This file pins the latest versions of the nix dependencies.

    4. Copy pipeline configuration: `.gitlab-ci.yml` for Gitlab, `.buildkite/pipeline.yml` for Buildkite or `.github/workflows/check.yml` for GitHub.

- Afterwards, adjust the template for your project:

    1. Replace `pataq-package` in `flake.nix` with your haskell package name (usually specified in `package.yaml`). If the root of your haskell project (directory containing `stack.yaml` or `cabal.project`) is not the same as the directory where `flake.nix` is ​​located, you need to set `src = ./.;` from `flake.nix` to the root of your haskell project.
       - **FOR APPLICATION:**  Replace `pataq-test` at the bottom of `flake.nix` with the name of the test component in your package.
       - **FOR LIBRARY:** List the GHC versions that will be used to build and test your library in the [`tested-with`](https://cabal.readthedocs.io/en/3.4/cabal-package.html#pkg-field-tested-with) stanza of the `.cabal` file and change `./pataq-package.cabal` in `ghc-versions` in `flake.nix` to the path to your `.cabal` file. If you are using GitHub actions, uncomment `ghc-matrix` in `flake.nix`, otherwise change `matrix` in the CI pipeline to the list of GHC versions specified in `ghc-versions`.
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

    3. If you're using `hpack` or `stack2cabal` in your project, make sure to uncomment the related lines in both `flake.nix` and pipeline configuration files. To avoid version mismatches, use `nix develop .#ci -c hpack` or `nix develop .#ci -c stack2cabal`.

    4. Make sure to clean up your `flake.nix` and pipeline configuration files by removing any optional code that is left commented out.

- Enjoy working CI!

## Impure tests

By default, these templates run Haskell tests in a pure nix builds, so it is not possible to access external resources such as a database or docker socket.

To get around this, you first need to provide a nix shell with the test executable along with other packages needed for the test environment.

Here, as an example, we provide a nix shell with the `pataq-package-test` executable, as well as two additional packages: `ephemeralpg`, used to create the ephemeral database, and `postgresql`, used to create the database schema:

```nix
devShells = {
  impure-tests = pkgs.mkShell {
    buildInputs = [
      hs-pkg.components.tests.pataq-package-test
      pkgs.ephemeralpg # we need pg_tmp to create an ephemeral db
      pkgs.postgresql # we need psql to create the db schema
    ];
  };
};
```

We then create a bash script that sets up the required environment and runs the `pataq-package-test`:

```bash
#!/usr/bin/env bash

# Set up the necessary environment
set -euo pipefail
export LANG="C.UTF-8"
export LC_ALL="C.UTF-8"
PSQL_CONNECTION_STRING=$(pg_tmp -t)
echo "Ephemeral PostgreSQL connection string: $PSQL_CONNECTION_STRING"

psql "$PSQL_CONNECTION_STRING" -f ./pataq-schema.sql

# some explanation for the env var magic below https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
portAndDb=${PSQL_CONNECTION_STRING##*:}

# Environment variables used by the test suite
export POSTGRES_PORT_TEST=${portAndDb%%/*}
export POSTGRES_USER_TEST=$(whoami)
export POSTGRES_DATABASE_TEST=test

# Run tests
pataq-package-test
```

And finally, we can run our impure tests from CI:

```
nix develop .#impure-tests -c ./impure-tests.sh
```

As an alternative solution, you can also use the [make-test-python](https://nixos.org/manual/nixos/unstable/index.html#sec-nixos-test-nodes) module, which uses a nixos virtual machine:

```nix
impure-tests = import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }:
  {
    name = "${hs-package-name}-tests";
    nodes = {

      # Define nixos VM
      testvm = { ... }: let
        dbUser = "postgres";
        dbName = "postgres";
        dbPort = 5342;
      in {
        virtualisation.memorySize = 1024;
        virtualisation.diskSize = 1024;

        # Set up the necessary environment
        services.postgresql = {
          enable = true;
          port = dbPort;
          initialScript = ./pataq-schema.sql;
          ensureDatabases = [ dbName ];
          ensureUsers = [
            { name = dbUser;
              ensurePermissions = {
                "DATABASE \"${dbName}\"" = "ALL PRIVILEGES";
              };
            }
          ];
          authentication = ''
            host  all  ${dbUser}  localhost  trust
          '';
        };

        # Environment variables used by the test suite
        environment.sessionVariables = {
          POSTGRES_PORT_TEST = builtins.toString dbPort;
          POSTGRES_USER_TEST = dbUser;
          POSTGRES_DATABASE_TEST = dbName;
        };
      };
    };

    testScript = ''
      #Strat VM
      start_all()

      # Wait until the postgres service is up and the port is open
      testvm.wait_for_unit("postgresql.service")
      testvm.wait_for_open_port(5432)

      # Run tests
      testvm.succeed("${hs-pkg.components.tests.pataq-package-test}/bin/pataq-package-test")

      # Shutdown VM
      testvm.shutdown()
    '';
}) { inherit pkgs system; };
```
