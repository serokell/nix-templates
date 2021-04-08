{
  description = "My Python application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        customOverrides = self: super: {
          # Overrides go here
        };

        app = pkgs.poetry2nix.mkPoetryApplication {
          projectDir = ./.;
          overrides =
            [ pkgs.poetry2nix.defaultPoetryOverrides customOverrides ];
        };

        packageName = throw "put your package name here";
      in {
        packages.${packageName} = app;

        defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ poetry ];
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
