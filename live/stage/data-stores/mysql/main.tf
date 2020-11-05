provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

module "database" {
  source = "../../../../modules/data-stores/mysql"

  db_name = "stagedb"
  db_username = "admin"
  db_password = data.aws_ssm_parameter.database_password.value
  identifier_prefix = "stage-"
  storage_size = 10
  db_instance_type = "db.t2.micro"
}

# Instead of storing the password in plaintext, pull it from Systems Manager (Parameter Store)
data "aws_ssm_parameter" "database_password" {
  name = "mysql-master-password-staging"
}