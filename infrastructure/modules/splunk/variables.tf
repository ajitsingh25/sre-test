variable "rds_private_subnet_az1" {
  description = "Private subnet ID AZ1 for EC2 instance"
  type        = string
}

variable "ami" {
  description = "AWS AMI"
  type        = string
  default     = "ami-0fc5d935ebf8bc3bc"
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "t3.small"
}

variable "vpc_id" {
  description = "The ID of the VPC where Splunk will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "public_subnet_ids" {
  description = "List of public subnets where the Classic Load Balancer will be deployed"
  type        = string
}

# variable "splunk_public_ip" {
#   description = "Public IP address of Splunk server"
#   type        = string
# }

variable "splunk_hec_token" {
  description = "Splunk HTTP Event Collector (HEC) Token"
  type        = string
  sensitive   = true
}

variable "api_gateway_log_group_name" {
  type = string
}

variable "get_task_lambda_log_group_name" {
  type = string
}

variable "post_task_lambda_log_group_name" {
  type = string
}

variable "rds_log_group_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "splunk_secret_docker" {
  type = string
}
