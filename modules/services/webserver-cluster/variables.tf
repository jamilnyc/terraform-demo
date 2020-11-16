variable "server_port" {
  description = "The port that the server listens to for HTTP requests"
  type = number
}

variable "cluster_name" {
  type = string
  description = "The name to use for all the cluster resources"
}

variable "db_remote_state_bucket" {
  type = string
  description = "The name of the S3 bucket for the database's remote state"
}

variable "db_remote_state_key" {
  type = string
  description = "The path for the database's remote state in S3"
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g., t2.micro)"
  type = string
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the auto-scaling group"
  type = number
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the auto-scaling group"
  type = number
}

variable "environment_name" {
  type = string
  description = "The name of the environment for identifying purposes"
}

variable "custom_tags" {
  type = map(string)
  description = "Custom tags to set on the Instances in the ASG"
  default = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type = bool
  default = false
}

variable "enable_new_user_data" {
  type = bool
  default = false
  description = "If set to true, use the new User Data Script"
}