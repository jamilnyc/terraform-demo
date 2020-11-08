terraform {
  backend "s3" {
    profile = "terraform"
    bucket = "jamil-demo-terraform-state"
    key = "stage/data-processing/queue/terraform.state"
    region = "us-east-1"
    dynamodb_table = "jamil-terraform-locks"
    encrypt = true
  }
}