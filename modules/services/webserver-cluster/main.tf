# Do not configure a provider in a module, that should be configured by the user of a module
# because providers contain information about the accounts to use, etc.

# Locals are like constants used throughout the module
locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "TCP"
  all_ips = ["0.0.0.0/0"]
}

# Data sources are read-only data from the provider
# Find the default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Find the Subnet ID's of the default VPC
data "aws_subnet_ids" "default_vpc_subnet_ids" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# Server configuration used by the Auto Scaling Group
# This is the template for servers used in the group
resource "aws_launch_configuration" "my_launch_cfg" {
  # Ubuntu 20.04
  image_id = "ami-0c43b23f011ba5061"
  instance_type = var.instance_type

  # Use the security group defined below to allow HTTP traffic on the defined port
  security_groups = [aws_security_group.my_server_sg.id]

  # Script to run after each instance is provisioned
  user_data = data.template_file.user_data.rendered

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  # Will create a new launch configuration first, assign it, then destroy the old one
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_auto_scaling_group" {
  # The EC2 instance definitions to use in this group
  launch_configuration = aws_launch_configuration.my_launch_cfg.name

  # Specifies which VPC subnets the EC2 instances should be deployed
  # Each subnet lives in a different availability zone (data center), so your application will still be up
  # even if one data center as an outage
  # Here we assign the subnets of the default VPC, that this group is using
  vpc_zone_identifier = data.aws_subnet_ids.default_vpc_subnet_ids.ids

  # The target group that this autoscaling group of EC2 servers lives inside
  target_group_arns = [aws_lb_target_group.autoscaling_target_group.arn]

  # Use the target group's health check, which is more robust than the simple EC2 check (just looks to see if VM is running)
  health_check_type = "ELB"

  # The number of instances to have at any given time
  min_size = var.min_size
  max_size = var.max_size

  # Tag each EC2 instance with this name
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "${var.cluster_name}-asg"
  }

  dynamic "tag" {
    for_each = var.custom_tags

    # The body of the inline object (like the static tag defined above)
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

# By default AWS does not allow incoming/outgoing traffic on port 8080
# This configuration allows the server to accept requests
# This will be applied to all servers in the Auto scaling group
resource "aws_security_group" "my_server_sg" {
  name = "${var.cluster_name}-instance"

  # Allow incoming traffic
  # This is an example of an inline block
  # It is preferred to use a separate resource as shown in "alb_sg"
  ingress {
    # from_port and to_port are used to specify a range of ports
    from_port = var.server_port
    to_port = var.server_port

    # The server wants to listen for HTTP requests, which are of course TCP
    protocol = local.tcp_protocol

    # Allow traffic from all IP addresses
    cidr_blocks = local.all_ips
  }
}

# Create an Application Load Balancer to balance incoming HTTP Traffic
# It is configured to use all the subnets in the default VPC
# AWS will automatically scale load balancers as needed into the appropriate AZ's
resource "aws_lb" "my_load_balancer" {
  name = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default_vpc_subnet_ids.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_load_balancer.arn
  port = local.http_port
  protocol = "HTTP"

  # Return a 404 by default, when no listener rules are matched
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: This isn't the page you're looking for. Move along."
      status_code  = 404
    }
  }
}

# By default, AWS does not allow any incoming/outgoing traffic for the ALB
# So you need to create a security group and specify that the ALB allows incoming traffic on port 80
# and also that outgoing traffic can be from any port
resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-alb-security-group"
}

# Allow incoming HTTP requests from anywhere
resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id

  # The range of ports to allow, just one in this case
  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port = local.any_port
  protocol = local.any_protocol
  to_port = local.any_port
  cidr_blocks = local.all_ips
}

# Target groups are groups of servers that requests should be routed to from the ALB
# A listener listens for requests that match a given protocol on a given port (in this case HTTP requests incoming on port 80 on the ALB)
# It then checks the listener rules for matching paths
# When a match occurs it is routed to a server in the target group for that rule
# Load Balancer port 80 ---> Application Web Server Port 8080
resource "aws_lb_target_group" "autoscaling_target_group" {
  name = "${var.cluster_name}-asg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default_vpc.id

  # Periodically check instances in the target group for their health
  # If an instance doesn't respond with an HTTP 200 OK response, it is considered unhealthy
  # Unhealthy servers will stop receiving traffic
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  # This rule is associated with the port 80 Listener
  listener_arn = aws_lb_listener.http_listener.arn

  priority = 100

  # Any incoming request paths will match
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  # Forward the request to the target group, that contains the autoscaling group of servers
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.autoscaling_target_group.arn
  }
}

# Read the state file, from the bucket that contains the database state
# This is read-only information
data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-1"
  }
}

# Read the script contents from the given filename and make the variables available
# to be interpolated in that file
data "template_file" "user_data" {
  # Using path.module means load user-data.sh from the module directory instead of the CWD where terraform is being executed
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.database.outputs.database_address
    db_port = data.terraform_remote_state.database.outputs.database_port
    environment_name = var.environment_name
  }
}