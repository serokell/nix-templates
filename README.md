# Nix and CI templates

This repository contains Nix and CI templates:

- [/haskell.nix](/haskell.nix) — Haskell application and library templates for Buildkite, Gitlab or GitHub CI using `haskell.nix`

- [/infra](/infra) — template for clusters with NixOS machines

- [/haskell-cabal2nix](/haskell-cabal2nix) — flake template for building a Haskell application with `cabal2nix`

- [/python-poetry2nix](/python-poetry2nix) — flake template for building a Python application with `poetry2nix`

- [/rust-crate2nix](/rust-crate2nix) — flake template for building a Rust application with `crate2nix`

**Note: The last three templates were originally used as examples for our [flake blog post](https://serokell.io/blog/practical-nix-flakes) and are no longer maintained.**

The general template for the repository, which contains the markdown files, licenses, configs for the haskell utilities, can be found in a [separate repository](https://github.com/serokell/metatemplates).
