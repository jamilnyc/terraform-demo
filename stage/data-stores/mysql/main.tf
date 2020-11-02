provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

# Create a MySQL database in AWS RDS
# This can take some time to create
resource "aws_db_instance" "my_db" {
  identifier_prefix = "terraform-demo"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_database"
  username = "admin"

  password = data.aws_ssm_parameter.database_password.value

  # For some reason skip_final_snapshot is true by default, but doesn't require an identifier
  # When true, it prevents deletion because there is no identifier
  skip_final_snapshot = true
  final_snapshot_identifier = "anything"
}

# Instead of storing the password in plaintext, pull it from Systems Manager (Parameter Store)
data "aws_ssm_parameter" "database_password" {
  name = "mysql-master-password-staging"
}