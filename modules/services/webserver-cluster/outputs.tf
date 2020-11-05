output "alb_dns_name" {
  value = aws_lb.my_load_balancer.dns_name
  description = "The DNS name of the load balance in front of the application servers"
}

output "asg_name" {
  value = aws_autoscaling_group.my_auto_scaling_group.name
  description = "The name of the Auto Scaling Group. Can be used to make custom scaling schedules"
}

output "alb_sg_name" {
  value = aws_security_group.alb_sg.name
  description = "The name of the ALB's security group. Can be used to add additional ingress/egress rules"
}