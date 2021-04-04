{
  description = "NixOS systems for internal services";

  inputs = {
    nixpkgs.url = "github:serokell/nixpkgs";
    serokell-nix.url = "github:serokell/serokell.nix";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    vault-secrets.url = "github:serokell/vault-secrets";
  };

  outputs = { self, nixpkgs, serokell-nix, deploy-rs, flake-utils, vault-secrets
    , ... }@inputs:
    let
      inherit (nixpkgs.lib) nixosSystem filterAttrs const recursiveUpdate;
      inherit (builtins) readDir mapAttrs;
      system = "x86_64-linux";
      servers = mapAttrs (path: _: import (./servers + "/${path}"))
        (filterAttrs (_: t: t == "directory") (readDir ./servers));
      mkSystem = config:
        nixosSystem {
          inherit system;
          modules = [ config ./common.nix ];
          specialArgs.inputs = inputs;
        };

      terraformFor = pkgs: pkgs.terraform.withPlugins (p: with p; [ aws ]);
    in {
      nixosConfigurations = mapAttrs (const mkSystem) servers;

      nixosModules = import ./modules;

      overlay = import ./packages;

      deploy = {
        magicRollback = true;
        autoRollback = true;
        sshOpts = [ "-p" "17788" ];
        nodes = mapAttrs (_: nixosConfig: {
          hostname =
            "${nixosConfig.config.networking.hostName}.${nixosConfig.config.networking.domain}";

          profiles.system.user = "root";
          profiles.system.path =
            deploy-rs.lib.${system}.activate.nixos nixosConfig;
        }) self.nixosConfigurations;
      };
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = serokell-nix.lib.pkgsWith nixpkgs.legacyPackages.${system} [
          serokell-nix.overlay
          vault-secrets.overlay
        ];
      in {

        packages = { inherit (pkgs.extend self.overlay) mtg; };

        devShell = pkgs.mkShell {
          VAULT_ADDR = "https://vault.serokell.org:8200";
          SSH_OPTS = "${builtins.concatStringsSep " " self.deploy.sshOpts}";
          buildInputs = [
            deploy-rs.packages.${system}.deploy-rs
            pkgs.vault
            (pkgs.vault-push-approle-envs self)
            (pkgs.vault-push-approles self)
            (terraformFor pkgs)
            pkgs.nixUnstable
          ];
        };

        checks = deploy-rs.lib.${system}.deployChecks self.deploy // {
          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          # FIXME VPC provider is not packaged
          # terraform = pkgs.runCommand "terraform-check" {
          #   src = ./terraform;
          #   buildInputs = [ (terraformFor pkgs) ];
          # } ''
          #   cp -r $src ./terraform
          #   terraform init -backend=false terraform
          #   terraform validate terraform
          #   touch $out
          # '';
        };
      });
}
