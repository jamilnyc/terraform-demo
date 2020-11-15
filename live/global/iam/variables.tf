variable "user_names" {
  description = "Create IAM users with these names"
  type = list(string)
  default = ["ash", "brock", "misty"]
}

variable "foods" {
  type = map(string)
  default = {
    apple = "fruit"
    carrot = "vegetable"
    cheese = "dairy"
  }
}