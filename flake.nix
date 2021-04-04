{
  description = "A collection of advanced flake templates";

  outputs = { self }: {

    templates = {

      haskell-cabal2nix = {
        path = ./haskell-cabal2nix;
        description = "A Haskell executable built with cabal2nix";
      };

      rust-crate2nix = {
        path = ./rust-crate2nix;
        description = "Cargo crate built with crate2nix";
      };

      infra = {
        path = ./infra;
        description = "An infrastructure repository";
      };

    };

  };
}
