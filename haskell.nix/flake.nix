{
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixpkgs.url = "github:serokell/nixpkgs";
    haskell-nix.url = "github:serokell/haskell.nix/serokell-latest";
    hackage-nix = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };
    stackage-nix = {
      url = "github:input-output-hk/stackage.nix";
      flake = false;
    };

    # if you want to run weeder:
    ##haskell-nix-weeder = {
    ##  url = "github:serokell/haskell-nix-weeder";
    ##  flake = false;
    ##};
  };

  outputs = { self, nixpkgs, haskell-nix, hackage-nix, stackage-nix, ... }:

  # for weeder:
  ##outputs = { self, nixpkgs, haskell-nix, hackage-nix, stackage-nix, haskell-nix-weeder, ... }:

    let
      haskellNix = import haskell-nix {
        sourcesOverride = { hackage = hackage-nix; stackage = stackage-nix; };
      };

      pkgs = import nixpkgs haskellNix.nixpkgsArgs;
      lib = pkgs.lib;

      # invoke haskell.nix
      hs-pkgs = pkgs.haskell-nix.stackProject {
        src = pkgs.haskell-nix.haskellLib.cleanGit {
          name = "pataq-package";
          src = ./.;
        };

        # haskell.nix configuration
        modules = [{
          packages.pataq-package = {
            ghcOptions = [
              # fail on warnings
              "-Werror"
              # disable optimisations to speed up builds
              "-O0"

              # for weeder: produce *.dump-hi files
              ##"-ddump-to-file" "-ddump-hi"
            ];

            # for weeder: collect all *.dump-hi files
            ##postInstall = weeder-hacks.collect-dump-hi-files;
          };

        }];
      };

      hs-pkg = hs-pkgs.pataq-package;

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

      # for weeder:
      ##weeder-hacks = import haskell-nix-weeder { inherit pkgs; };

      # nixpkgs has weeder 2, but we use weeder 1
      ##weeder-legacy = pkgs.haskellPackages.callHackageDirect {
      ##  pkg = "weeder";
      ##  ver = "1.0.9";
      ##  sha256 = "0gfvhw7n8g2274k74g8gnv1y19alr1yig618capiyaix6i9wnmpa";
      ##} {};

      # a derivation which generates a script for running weeder
      ##weeder-script = weeder-hacks.weeder-script {
      ##  weeder = weeder-legacy;
      ##  hs-pkgs = hs-pkgs;
      ##  local-packages = [
      ##    { name = "pataq-package"; subdirectory = "."; }
      ##  ];
      ##};

    in {
      # nixpkgs revision pinned by this flake
      legacyPackages.x86_64-linux = pkgs;

      # derivations that we can run from CI
      checks.x86_64-linux = {
        # builds all haskell components
        build-all = all-components;

        # runs the test
        test = hs-pkg.checks.pataq-test;
      };

      # script for running weeder
      ##weeder-script = weeder-script;
    };
}
