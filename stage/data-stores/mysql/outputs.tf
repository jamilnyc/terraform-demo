output "database_address" {
  value = aws_db_instance.my_db.address
  description = "Use this address to connect to the database"
}

output "database_port" {
  value = aws_db_instance.my_db.port
  description = "The port the DB is listening on"
}