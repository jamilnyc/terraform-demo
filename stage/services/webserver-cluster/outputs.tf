output "alb_dns_name" {
  value = aws_lb.my_load_balancer.dns_name
  description = "The DNS name of the load balance in front of the application servers"
}