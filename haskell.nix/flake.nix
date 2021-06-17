{
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixpkgs.url = "github:serokell/nixpkgs";
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    hackage-nix = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };
    stackage-nix = {
      url = "github:input-output-hk/stackage.nix";
      flake = false;
    };

    flake-utils = { url = "github:numtide/flake-utils"; };

    ## for weeder:
    #haskell-nix-weeder = {
    # url = "github:serokell/haskell-nix-weeder";
    # flake = false;
    #};
  };

  outputs =
    { self, nixpkgs, haskell-nix, hackage-nix, stackage-nix, flake-utils, ... }@args:

    # If you want to support systems other than x86_64-linux, add them here
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:

      let
        name = throw "Put your package name here";

        haskellNixOverlays = haskell-nix.internal.overlaysOverrideable {
          sourcesOverride = haskell-nix.internal.sources // {
            hackage = hackage-nix;
            stackage = stackage-nix;
          };
        };

        pkgs = nixpkgs.legacyPackages.${system}.extend
          haskellNixOverlays.combined-eval-on-build;
        lib = pkgs.lib;

        # invoke haskell.nix
        hs-pkgs = pkgs.haskell-nix.stackProject {
          src = pkgs.haskell-nix.haskellLib.cleanGit {
            inherit name;
            src = ./.;
          };

          # haskell.nix configuration
          modules = [{
            packages.text-icu = { ghcOptions = [ ]; };
            packages.${name} = {
              ghcOptions = [
                # fail on warnings
                "-Werror"
                # disable optimisations, we don't need them if we don't package or deploy the executable
                "-O0"

                ## for weeder: produce *.dump-hi files
                #"-ddump-to-file" "-ddump-hi"
              ];

              ## for weeder: collect all *.dump-hi files
              #postInstall = weeder-hacks.collect-dump-hi-files;
            };

          }];
        };

        hs-pkg = hs-pkgs.${name};

        # returns the list of all components for a package
        get-package-components = pkg:
          # library
          lib.optional (pkg ? library) pkg.library
          # haddock
          ++ lib.optional (pkg ? library) pkg.library.haddock
          # exes, tests and benchmarks
          ++ lib.attrValues pkg.exes ++ lib.attrValues pkg.tests
          ++ lib.attrValues pkg.benchmarks;

        # all components for the current haskell package
        all-components = get-package-components hs-pkg.components;

        # derivations that actually run the tests
        hs-checks = nixpkgs.lib.filterAttrs (_: nixpkgs.lib.isDerivation) hs-pkg.checks;

        ## for weeder:
        #weeder-hacks = import args.haskell-nix-weeder { inherit pkgs; };

        ## nixpkgs has weeder 2, but we use weeder 1
        #weeder-legacy = pkgs.haskellPackages.callHackageDirect {
        #  pkg = "weeder";
        #  ver = "1.0.9";
        #  sha256 = "0gfvhw7n8g2274k74g8gnv1y19alr1yig618capiyaix6i9wnmpa";
        #} {};

        ## a derivation which generates a script for running weeder
        #weeder-script = weeder-hacks.weeder-script {
        #  weeder = weeder-legacy;
        #  hs-pkgs = hs-pkgs;
        #  local-packages = [
        #    { inherit name; subdirectory = "."; }
        #  ];
        #};

      in {

        ## In case the package contains exes,
        # packages = hs-pkg.components.exes;

        ## In case the package contains some "main" exe that shares the name with the package,
        # defaultPackage = hs-pkg.components.exes.${name};

        # nixpkgs revision pinned by this flake
        legacyPackages = pkgs;

        # derivations that we can run from CI, or locally with `nix flake check`
        checks = {
          # builds all haskell components
          build-all = pkgs.buildEnv {
            name = "${name}-all-components";
            ignoreCollisions = true;
            paths = all-components;
          };

          # runs the tests
        } // hs-checks;

        ## script for running weeder
        #weeder-script = weeder-script;
      });
}
