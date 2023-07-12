{
  nixConfig = {
    flake-registry = "https://github.com/serokell/flake-registry/raw/master/flake-registry.json";
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      flake = false;
    };
    haskell-nix = {
      inputs.hackage.follows = "hackage";
      inputs.stackage.follows = "stackage";
    };
    hackage = {
      flake = false;
    };
    stackage = {
      flake = false;
    };
  };

  outputs = { self, nixpkgs, haskell-nix, hackage, stackage, serokell-nix, flake-compat, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem(system:
    let
      haskellPkgs = haskell-nix.legacyPackages."${system}";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          serokell-nix.overlay
        ];
      };

      lib = pkgs.lib;

      hs-package-name = "pataq-package";

      # invoke haskell.nix
      hs-pkgs = haskellPkgs.haskell-nix.stackProject {
        src = haskellPkgs.haskell-nix.haskellLib.cleanGit {
          name = hs-package-name;
          # specify the path to the root of your haskell project (the directory containing stack.yaml or cabal.project)
          src = ./.;
        };

        # haskell.nix configuration
        modules = [{
          packages.${hs-package-name} = {
            ghcOptions = [
              # fail on warnings
              "-Werror"
              # disable optimisations, we don't need them if we don't package or deploy the executable
              "-O0"
            ];
          };

        }];
      };

      hs-pkg = hs-pkgs.${hs-package-name};

      # returns the list of all components for a package
      get-package-components = pkg:
        # library
        lib.optional (pkg ? library) pkg.library
        # haddock
        ++ lib.optional (pkg ? library) pkg.library.haddock
        # exes, tests and benchmarks
        ++ lib.attrValues pkg.exes
        ++ lib.attrValues pkg.tests
        ++ lib.attrValues pkg.benchmarks;

      # all components for the current haskell package
      all-components = get-package-components hs-pkg.components;

      # Uncomment if your project uses stack2cabal to generate cabal files
      # stack2cabal = haskellPkgs.haskell.lib.overrideCabal haskellPkgs.haskellPackages.stack2cabal
      # (drv: { jailbreak = true; broken = false; });

    in {
      # nixpkgs revision pinned by this flake
      legacyPackages = pkgs;

      # Uncomment if your project uses hpack or stack2cabal to update cabal files, remove the one you don't use
      # To avoid version mismatches, use `nix develop .#ci -c hpack` or `nix develop .#ci -c stack2cabal`
      # devShell = {
      #   ci = pkgs.mkShell {
      #     buildInputs = [
      #       pkgs.hpack
      #       stack2cabal
      #     ];
      #   };
      # };

      # derivations that we can run from CI
      checks = {
        # builds all haskell components
        build-all = pkgs.linkFarmFromDrvs "build-all" all-components;

        # runs the test
        test = hs-pkg.checks.pataq-test;

        trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
        reuse-lint = pkgs.build.reuseLint ./.;
        # Uncomment in case your project sources contain bash scripts
        # shellcheck = pkgs.build.shellcheck ./.;

        hlint = pkgs.build.haskell.hlint ./.;
        stylish-haskell = pkgs.build.haskell.stylish-haskell ./.;
        # Uncomment if your project uses hpack to generate cabal files
        # hpack = pkgs.build.haskell.hpack ./.;
      };
    });
}
