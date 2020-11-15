# When using `count` the resource is turned into an array
# Use a numerical index to access a single element
//output "first_user" {
//  value = aws_iam_user.users[0].arn
//}

# User an asterisk to access all the elements as an array
//output "all_arns" {
//  value = aws_iam_user.users[*].arn
//}

/**
 * The equivalent way of making a list of ARN's with `for_each` instead of count.
 * Since the resources are in a map, we must extract the values first into a list.
 */
output "all_arns" {
  value = values(aws_iam_user.users)[*].arn
}

