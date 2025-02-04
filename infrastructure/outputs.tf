# ✅ Outputs for reference
output "rds_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS database endpoint"
}

output "s3_bucket_id" {
  value       = module.s3.s3_bucket_id
  description = "The ID of the S3 bucket"
}

output "s3_bucket_domain" {
  value       = module.s3.s3_bucket_domain
  description = "S3 bucket domain"
}

output "cloudfront_url" {
  value       = "https://${module.cloudfront.cloudfront_distribution_domain_name}"
  description = "CloudFront Distribution URL"
}

output "cloudwatch_dashboard_url" {
  value       = module.cloudwatch.cloudwatch_dashboard_url
  description = "URL of the CloudWatch dashboard"
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}
