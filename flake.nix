# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

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

      python-poetry2nix = {
        path = ./python-poetry2nix;
        description = "Python project built with poetry2nix";
      };

      infra = {
        path = ./infra;
        description = "An infrastructure repository";
      };

      haskell-application = {
        path = ./haskell.nix/application;
        description = "Stack project built with haskell.nix";
      };

      haskell-library = {
        path = ./haskell.nix/library;
        description = "Haskell library built and tested with different versions of ghc";
      };

      generic = {
        path = ./generic;
        description = "A generic Nix flake with development shell and CI checks";
    };
  };
}
