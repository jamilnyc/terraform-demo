# Declare variables in this file

variable "server_port" {
  description = "The port that the server listens to for HTTP requests"
  type = number
  default = 8080
}