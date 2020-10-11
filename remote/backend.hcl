# Partial configuration to fill in the missing values from the backend block
# Usage: terraform init -backend-config=backend.hcl
bucket = "jamil-terraform-state"
region = "us-east-1"
dynamodb_table = "terraform-locks-table"
encrypt = true