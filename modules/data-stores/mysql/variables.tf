variable "identifier_prefix" {
  type = string
  description = "Prefix for the RDS instance"
}

variable "storage_size" {
  type = number
  description = "The allocated storage size in GiB"
}

variable "db_instance_type" {
  type = string
  description = "The instance type of the RDS instance"
  default = "db.t2.micro"
}

variable "db_name" {
  type = string
  description = "The name of the database that is created when this instance is created"
}

variable "db_username" {
  type = string
  default = "admin"
}

variable "db_password" {
  type = string
}