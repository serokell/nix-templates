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
    flake-utils.lib.eachDefaultSystem (system:
      let
        haskellPkgs = haskell-nix.legacyPackages."${system}";
        inherit (serokell-nix.lib) cabal;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            serokell-nix.overlay
          ];
        };

        lib = pkgs.lib;

        hs-package-name = "pataq-package";

        ghc-versions = cabal.getTestedWithVersions ./pataq-package.cabal;

        # invoke haskell.nix for each ghc version listed in ghc-versions
        pkgs-per-ghc = lib.genAttrs ghc-versions
          (ghc: haskellPkgs.haskell-nix.cabalProject {
            src = haskellPkgs.haskell-nix.haskellLib.cleanGit {
              name = hs-package-name;
              src = ./.;
            };
            compiler-nix-name = ghc;

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
          });

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

        # all components for each specified ghc version
        build-all = lib.mapAttrs'
          (ghc: pkg:
            let components = get-package-components pkg.${hs-package-name}.components;
            in lib.nameValuePair "${ghc}:build-all"
              (pkgs.linkFarmFromDrvs "build-all" components)) pkgs-per-ghc;

        # all tests for each specified ghc version
        test-all = lib.mapAttrs'
          (ghc: pkg:
            let tests = lib.filter lib.isDerivation
              (lib.attrValues pkg.${hs-package-name}.checks);
            in lib.nameValuePair "${ghc}:test-all"
              (pkgs.linkFarmFromDrvs "test-all" tests)) pkgs-per-ghc;

        # Uncomment if your project uses stack2cabal to generate cabal files
        # stack2cabal = haskellPkgs.haskell.lib.overrideCabal haskellPkgs.haskellPackages.stack2cabal
        # (drv: { jailbreak = true; broken = false; });

      in {
        # nixpkgs revision pinned by this flake
        legacyPackages = pkgs;

        # Uncomment if your project uses GitHub actions
        # ghc-matrix = {
        #   include = map (ver: { ghc = ver; }) ghc-versions;
        # };

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
        checks = build-all // test-all // {

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
