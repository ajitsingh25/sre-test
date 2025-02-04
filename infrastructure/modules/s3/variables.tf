variable "bucket_name" {
  description = "Name prefix for the S3 bucket"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution for bucket policy"
  type        = string
  default     = ""
}

variable "api_gateway_url" {
  description = "The base URL for API Gateway"
  type        = string
  default     = ""
}

variable "enable_s3_config" {
  description = "Enable S3 configuration including policy and file upload"
  type        = bool
  default     = true
}
