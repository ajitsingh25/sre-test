output "vpc_id" {
  value       = data.aws_vpc.default.id
  description = "Default VPC ID"
}

output "subnet_ids" {
  value       = data.aws_subnets.default.ids
  description = "List of default subnet IDs"
}

output "lambda_sg_id" {
  value       = aws_security_group.lambda_sg.id
  description = "Security Group ID for Lambda"
}

output "rds_sg_id" {
  value       = aws_security_group.rds_sg.id
  description = "Security Group ID for RDS"
}

output "rds_proxy_sg_id" {
  value       = aws_security_group.rds_proxy_sg.id
  description = "Security Group ID for RDS Proxy"
}

output "rds_private_subnet_ids" {
  value       = [aws_subnet.rds_private_subnet_az1.id, aws_subnet.rds_private_subnet_az2.id]
  description = "List of private subnet IDs where RDS is hosted"
}

output "rds_private_subnet_az1" {
  value = aws_subnet.rds_private_subnet_az1.id
}

output "availability_zone_1" {
  value = data.aws_availability_zones.available.names[0]
}

output "secrets_manager_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.secrets_manager.id
  description = "ID of the VPC Endpoint for AWS Secrets Manager"
}

output "public_subnet" {
  value = aws_subnet.public_subnet.id
}
