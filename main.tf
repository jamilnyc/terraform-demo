provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

variable "server_port" {
  description = "The port that the server listens to for HTTP requests"
  type = number
}

output "server_public_ip" {
  value = aws_instance.my_server.public_ip
  description = "The public IP address to access the web server"
}

# Create an Ubuntu 20.04 (Focal) VM
resource "aws_instance" "my_server" {
  ami = "ami-0c43b23f011ba5061"
  instance_type = "t2.micro"

  # Adds a name visible in the EC2 instances dashboard
  tags = {
    Name = "terraform-example"
  }

  # Terraform's heredoc syntax to create multi-line strings
  # This script will execute immediately after the server is provisioned
  # It creates a simple webserver listening on port 8080
  # To use a variable in a heredoc or string, use the format ${var.variable_name_here}
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World!" >> index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  # Associate the security group defined below to this EC2 instance
  # List of all exported attributes for a security group resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#attributes-reference
  vpc_security_group_ids = [aws_security_group.my_server_sg.id]
}

# By default AWS does not allow incoming/outgoing traffic on port 8080
# This configuration allows the server to accept requests
resource "aws_security_group" "my_server_sg" {
  name = "terraform-example-security-group"

  # Allow incoming traffic
  ingress {
    # from_port and to_port are used to specify a range of ports
    from_port = var.server_port
    to_port = var.server_port

    # The server wants to listen for HTTP requests, which are of course TCP
    protocol = "TCP"

    # Allow traffic from all IP addresses
    cidr_blocks = ["0.0.0.0/0"]
  }
}