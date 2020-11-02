# There is a bit of a chicken/egg situation where you want to store your state remotely
# but you also want to create the resources to store your state with terraform.
# So first you need to init and apply JUST the creation of the S3 and DynamoDB resources
# Then you can enable the section with the backend configuration and apply that
# You can use the same bucket and table across all your Terraform code, so it only needs to be created once
# Use a different key for each in that case

provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

# Create an S3 bucket to hold our state file
resource "aws_s3_bucket" "terraform_state" {
  # This is a unique name that should be changed
  # Otherwise you will run into a BucketAlreadyExists error
  bucket = "jamil-demo-terraform-state"

  # Prevent Terraform from deleting this bucket
  # Attempting to do so will cause an error
  # You can comment it out if you wan to really delete it
  lifecycle {
    prevent_destroy = true
  }

  # Keep a separate version for each revision of our state file
  # Allows you to revert to an older version if needed
  versioning {
    enabled = true
  }

  # Encrypt the contents of this bucket
  # This is especially important since our state file will contain secrets and such
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# The state file will use this table to manage locks when multiple people access the it
resource "aws_dynamodb_table" "terraform_locks" {
  name = "jamil-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"

  # This must be the name of the primary key, exactly
  hash_key = "LockID"

  attribute {
    # String field
    name = "LockID"
    type = "S"
  }
}

# Specify where you want to store your remote state
terraform {
  backend "s3" {
    profile = "terraform"
    bucket = "jamil-demo-terraform-state"

    # Path where the state file will be written to
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "jamil-terraform-locks"

    # Ensure your state is encrypted on disk
    # This is on top of the existing encryption on the bucket as a whole
    encrypt = true
  }
}