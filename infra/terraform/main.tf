# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

terraform {
  backend "s3" {
    bucket = "serokell-"Constellation name here"-tfstate"
    dynamodb_table = "serokell-"Constellation name here"-tfstate-lock"
    encrypt = true
    key    = Constellation name here "/terraform.tfstate"
    region = "eu-west-2"
  }
  ## Prevent unwanted updates
  required_version = "= 0.12.29" # Use nix-shell or nix develop
}

# Grab the latest NixOS AMI built by Serokell
data "aws_ami" "nixos" {
  most_recent = true

  filter {
    name = "name"
    values = ["NixOS-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["920152662742"] # Serokell
}

# Allow ALL egress traffic
resource "aws_security_group" "egress_all" {
  name = "egress_all"
  description = "Allow inbound and outbound egress traffic"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow traffic for the prometheus exporter
resource "aws_security_group" "prometheus_exporter_node" {
  name = "prometheus_exporter_node"
  description = "Allow Prometheus Node Exporter data scraping"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 9100
    to_port = 9100
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow SSH traffic
resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "Allow inbound and outbound traffic for ssh"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 17788
    to_port = 17788
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow HTTP(S) traffic
resource "aws_security_group" "http" {
  name = "http"
  description = "Allow inbound and outbound http(s) traffic"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
