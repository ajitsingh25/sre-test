output "s3_bucket_id" {
  value       = module.s3_bucket.s3_bucket_id
  description = "The ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = module.s3_bucket.s3_bucket_arn
  description = "S3 Bucket ARN"
}

output "s3_bucket_domain" {
  value = module.s3_bucket.s3_bucket_bucket_domain_name
}

output "s3_bucket_regional_domain" {
  value = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}
