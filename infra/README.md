# ♊ Gemini: Internal Services Cluster

![Gemini Constellation](https://upload.wikimedia.org/wikipedia/commons/d/d1/GeminiCC.jpg)

_Image credit: Till Credner, CC BY-SA 3.0_

Serokell's internal services.

All AWS resources are managed by Terraform. Machine configuration is managed
with Nix, and all machines run NixOS.

All necessary programs and dependencies are provided by Nix in `nix-shell` or `nix develop`.

## Repository layout

- [./terraform](./terraform) contains terraform expressions used to deploy
  all EC2 servers and Route53 zones&records for tezos.serokell.team and tezosagora.org

- [./common.nix](./common.nix) provides common NixOS configuration defaults
  for all servers

- [./modules](./modules) contains NixOS modules that aren't used outside
  the repo but could still be reused some day

- [./servers](./servers) contains NixOS server descriptions. Usually just
  imports a profile and changes the default values to specific ones

- [./flake.nix](./flake.nix) defines repository dependencies, passes them
  down to `servers` and builds the final NixOS systems to be deployed. Also
  defines a `devShell` containing packages used to deploy this repo and a
  `deploy` attribute which describes how to deploy NixOS systems to servers.

- `./flake.lock` is a lockfile containing dependency pins (git revisions)
- `./default.nix` and `./shell.nix` are for pre-flake nix compatibility.

## Servers

| Name    | Function       | IP |
|:-------:|:--------------:|:--:|
| Mekbuda | MTProxy server |    |

<!-- Don't forget to add the servers on https://www.notion.so/serokell/Server-Naming-Scheme-c189819000164fb090377c75e4ce7da6 -->

## Deployment

### Terraform

Cloud hardware required to run this repository is described using Terraform.
Terraform is an Infrastructure as Code tool from Hashicorp. Read more [here](https://www.terraform.io/).

Terraform version that is used in this repo is pinned. Please use `nix-shell`
or `nix develop` to get it.

Terraform resources are declared in `terraform/`.

The first time you use it, you need to run `terraform init` in that directory.
This will initialize local state and download any missing plugins.

Your main workhorse will be `terraform apply`, which will print a diff view of
any resource changes, and ask you whether you want to commit them. Please read
this output carefully, as Terraform will not hesitate to nuke anything it thinks
needs nuking.

### NixOS

Server configurations are described in `./servers`.

To deploy all the servers, enter a shell (with `nix develop` or `nix-shell`)
and run `deploy`.

You may wish to read `deploy --help` to understand how to use the tool.

### Secrets

Secrets are stored in Vault. Serokell employees with Admin-level access
need to generate approle credentials and push them to servers in order
for services to work after redeployment. Example of how to do so:

```
$ # Enter a shell with dependencies and variables set
$ nix develop # or nix-shell
$ # Authenticate to vault
$ vault login # You may need to specify the login method
$ # Generate and push approles with accompanying security policies to Vault
$ vault-push-approles
<interaction omitted>
$ # Fetch approle credentials from Vault and push them to the server
$ vault-push-approle-envs
<interaction omitted>
```
