variable "db_identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Master database username"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "security_group_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of RDS instance"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before RDS deletion"
  type        = bool
  default     = true
}

variable "rds_subnet_ids" {
  description = "List of private subnets for RDS across multiple AZs"
  type        = list(string)
}

variable "rds_proxy_role_arn" {
  description = "IAM Role ARN for RDS Proxy"
  type        = string
}

variable "proxy_security_group_id" {
  description = "Security Group ID for RDS Proxy"
  type        = string
}
