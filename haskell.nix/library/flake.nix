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
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            serokell-nix.overlay
          ];
        };

        lib = pkgs.lib;
        ci = serokell-nix.lib.haskell.makeCI haskellPkgs {
          # specify the path to the root of your haskell project (the directory containing stack.yaml or cabal.project)
          src = ./.;
          # you can specify a list of ghc versions to build packages,
          # if not specified the ghc versions will be taken from tested-with stanzas from .cabal files
          # ghcVersions = [ "ghc902" "ghc926" ];
          # you can specify additional stack yaml files in addition to stack.yaml
          # stackFiles = [ "stack-lts-21-5.yaml" ];
          # you can specify additional stack resolvers, they will be replaced in stack.yaml
          # resolvers = [ "lts-19.13" ];
          # you can disable building with stack if your project does not use stack
          # buildWithStack = false;
          # haskell.nix configuration
          extraArgs = {
            modules = [
              (serokell-nix.lib.haskell.optionsLocalPackages {
                ghcOptions = [
                  # fail on warnings
                  "-Werror"
                  # disable optimisations, we don't need them if we don't package or deploy the executable
                  "-O0"
                ];
              })
            ];
          };
        };
        
        # Uncomment if your project uses stack2cabal to generate cabal files
        # stack2cabal = haskellPkgs.haskell.lib.overrideCabal haskellPkgs.haskellPackages.stack2cabal
        # (drv: { jailbreak = true; broken = false; });

      in {
        # nixpkgs revision pinned by this flake
        legacyPackages = pkgs;

        # Uncomment if your project uses GitHub actions
        # inherit (ci) build-matrix;

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
        checks = ci.build-all // ci.test-all // {

          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          reuse-lint = pkgs.build.reuseLint ./.;
          # Uncomment in case your project sources contain bash scripts
          # shellcheck = pkgs.build.shellcheck ./.;

          hlint = pkgs.build.haskell.hlint ./.;
          stylish-haskell = pkgs.build.haskell.stylish-haskell ./.;
          cabal-check = pkgs.build.haskell.cabal-check ./.;
          # Uncomment if your project uses hpack to generate cabal files
          # hpack = pkgs.build.haskell.hpack ./.;
        };
      });
}
