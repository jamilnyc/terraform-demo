terraform {
  backend "s3" {
    profile = "terraform"
    bucket = "jamil-demo-terraform-state"
    key = "stage/services/webserver-cluster/terraform.state"
    region = "us-east-1"
    dynamodb_table = "jamil-terraform-locks"
    encrypt = true
  }
}