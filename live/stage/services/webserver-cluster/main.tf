provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

# A module is just a directory of terraform files
module "webserver_cluster" {
  # Basically all the *.tf code in the source directory into this file
  # This can also be a GitHub URL
  source = "../../../../modules/services/webserver-cluster"

  # Provide values for all the variables defined in the module
  # This makes sure that names are specfic to their environment and you don't get collisions between stage and prod
  environment_name = "Stage"
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "jamil-demo-terraform-state"
  db_remote_state_key = "stage/data-stores/mysql/terraform.state"
  server_port = 8080
  instance_type = "t2.micro"
  min_size = 2
  max_size = 3
  enable_autoscaling = false
  enable_new_user_data = true

  custom_tags = {
    Owner = "team-foo"
    DeployedBy = "terraform"
  }
}