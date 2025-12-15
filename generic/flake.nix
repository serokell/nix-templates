{
  nixConfig = {
    flake-registry =
      "https://github.com/serokell/flake-registry/raw/master/flake-registry.json";
  };

  outputs = { self, nixpkgs, serokell-nix, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ serokell-nix.overlay ];
        };
      in {
        # nixpkgs revision pinned by this flake
        legacyPackages = pkgs;

        devShells = {
          default = pkgs.mkShell {
            buildInputs = [
              # Add here tools you need in your development shell
            ];
          };
        };

        # derivations that we can run from CI
        checks = {
          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          reuse-lint = pkgs.build.reuseLint ./.;
          # Uncomment in case your project sources contain bash scripts
          # shellcheck = pkgs.build.shellcheck ./.;
        };
      });
}
