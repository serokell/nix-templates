<!-- SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/> -->

<!-- SPDX-License-Identifier: CC0-1.0 -->

# Terraform files for Gemini

DynamoDB and tfstate bucket in [./state.tf](./state.tf)

Pinned provider versions in [./provider.tf](./provider.tf)

AWS servers and DNS records in [./main.tf](./main.tf)

To bootstrap, comment out `main.tf`, `terraform apply`, then uncomment and `terraform apply` again.
