# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

## Bucket for TF state storage
resource "aws_s3_bucket" "tfstate" {
  bucket = "serokell-"Constellation name here"-tfstate"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

## DynamoDB for TF locking and state
resource "aws_dynamodb_table" "tfstatelock" {
  name = "serokell-"CoConstellation name here"-tfstate-lock"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  lifecycle {
    prevent_destroy = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }
}
