output "splunk_ec2_private_ip" {
  value       = aws_instance.splunk_server.private_ip
  description = "Private IP of Splunk EC2 instance"
}

output "splunk_lb_dns" {
  value       = aws_elb.splunk_lb.dns_name
  description = "Public DNS name of the Classic Load Balancer for Splunk"
}
