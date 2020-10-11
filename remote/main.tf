provider "aws" {
  region = "us-east-1"
}

# We will store our state remotely in an S3 bucket defined below
resource "aws_s3_bucket" "terraform_state" {
  # Bucket names must be globally unique
  bucket = "jamil-terraform-state"

  # Prevent terraform operations from deleting this resource, including `terraform destroy`
  lifecycle {
    prevent_destroy = true
  }

  # Every update to the file, creates a new file
  # Good for recovery from an error state
  versioning {
    enabled = true
  }

  # Encrypt the state file when stored in S3
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# To support locking (preventing multiple people from writing to the state file at once), we need
# a place to store lock data, so will create a DynamoDB instance
resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-locks-table"
  billing_mode = "PAY_PER_REQUEST"

  # Similar to primary key
  hash_key = "LockID"

  # Define a column named "LockID", data type of string
  attribute {
    name = "LockID"
    type = "S"
  }
}

# The S3 bucket and DynamoDB table above must both be created BEFORE
# you attempt to use them as the remote state source. Therefore, comment
# out the following during the first initialization

terraform {
  backend "s3" {
    # Specify the bucket named above, with the directory to store the state file in
    bucket = "jamil-terraform-state"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"

    # We might want to reference the name from the resource above, but terraform backends
    # do not allow the use of variables in their block
    dynamodb_table = "terraform-locks-table"

    # Encrypt the state file itself, in addition to the bucket being encrypted
    encrypt = true
  }
}

output "state_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket where our state is stored."
}

output "locks_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table where we store our locks"
}