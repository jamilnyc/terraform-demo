provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

# Create an Ubuntu 20.04 (Focal) VM
resource "aws_instance" "example" {
  ami = "ami-0c43b23f011ba5061"
  instance_type = "t2.micro"

  # Adds a name visible in the EC2 instances dashboard
  tags = {
    Name = "terraform-example"
  }
}