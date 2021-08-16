# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

{ config, inputs, ... }:
let
  constellation = throw "Set a constellation name!";
  inherit (config.networking) hostName;
in
{
  imports = [
    inputs.serokell-nix.nixosModules.common
    inputs.serokell-nix.nixosModules.serokell-users
    inputs.vault-secrets.nixosModules.vault-secrets
  ];

  networking.domain = "${constellation}.serokell.team";

  vault-secrets = {
    vaultPrefix = "kv/sys/${constellation}/${hostName}";
    vaultAddress = "https://vault.serokell.org:8200";
    approlePrefix = "${constellation}-${hostName}";
  };
}
