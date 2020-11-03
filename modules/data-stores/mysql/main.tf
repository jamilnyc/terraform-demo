# Create a MySQL database in AWS RDS
# This can take some time to create
resource "aws_db_instance" "my_db" {
  identifier_prefix = var.identifier_prefix
  engine = "mysql"
  allocated_storage = var.storage_size
  instance_class = var.db_instance_type
  name = var.db_name
  username = var.db_username

  password = var.db_password

  # For some reason skip_final_snapshot is true by default, but doesn't require an identifier
  # When true, it prevents deletion because there is no identifier
  skip_final_snapshot = true
  final_snapshot_identifier = "anything"
}

