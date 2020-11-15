provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

/**
 * One way to create multiple IAM users
 * `count` is the number of copies to make of this resource
 * `count.index` is the copy number (starting at 0)
 * The expression "users" is now a list of resources with numerical indexes
 */
//resource "aws_iam_user" "users" {
//  count = length(var.user_names)
//  name = var.user_names[count.index]
//}


/**
 * `for_each` operates on either sets or maps (it does not support lists, so we have to cast it)
 * You can access the key with `each.key` (maps) and the value with `each.value` (maps and sets)
 * The expression "users" is now a map with the original list values as keys
 */
resource "aws_iam_user" "users" {
  for_each = toset(var.user_names)
  name = each.value
}