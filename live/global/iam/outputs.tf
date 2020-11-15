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
  description = "A list of AWS ARN's for each user created"
}


/**
 * An example of how apply a function to a list of values.
 * Note that it is surrounded by square brackets [] because the end result is a list
 * Wrap in curly braces {} to make the result a map
 *
 * Example:
 * {for item in var.my_list : output_key => output_value}
 */
output "upper_case_names" {
  value = [for name in var.user_names : upper(name)]
  description = "The list of names, all converted to uppercase"
}

/**
 * An example of how to add a condition when looping over values
 */
output "short_upper_case_names" {
  value = [for name in var.user_names : upper(name) if length(name) < 5]
  description = "A list of short names only, converted to uppercase"
}


/**
 * An example of how to loop over a map.
 * The logic described above applies if you want to output a map or a list.
 */
output "loop_map_to_list" {
  value = [for key, value in var.foods: "A ${key} is a ${value}"]
}

/**
 * An example of how to use a loop inside a string.
 * The tilde ~ signifies that extra white space should be removed.
 */
output "loop_in_string" {
  value = <<EOF
%{ for name in var.user_names}
  ${name}
%{~ endfor}
EOF
}