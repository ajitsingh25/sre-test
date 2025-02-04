output "cloudfront_distribution_arn" {
  value       = module.cloudfront.cloudfront_distribution_arn
  description = "CloudFront distribution ARN"
}

output "cloudfront_distribution_domain_name" {
  value       = module.cloudfront.cloudfront_distribution_domain_name
  description = "CloudFront distribution domain name"
}
