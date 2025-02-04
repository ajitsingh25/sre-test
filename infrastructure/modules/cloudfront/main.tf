# ✅ Enable CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "sre-cloudfront-oac"
  description                       = "OAC for S3 Static Site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ✅ CloudFront Distribution
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.0"

  comment = "CloudFront for S3 Frontend"

  origin = {
    s3 = {
      domain_name              = var.s3_bucket_regional_domain # ✅ Use Private S3 Access
      origin_id                = "s3-origin"
      origin_access_control_id = aws_cloudfront_origin_access_control.oac.id # ✅ Use OAC
    }
  }

  default_cache_behavior = {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values = {
      query_string = false
      cookies      = "none"
    }
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}

# ✅ Trigger CloudFront Invalidation When S3 Files Change
resource "null_resource" "invalidate_cloudfront" {
  triggers = {
    frontend_files_hash = filemd5("${path.root}/../frontend/index.html") # Track frontend file changes
  }

  provisioner "local-exec" {
    command = <<EOT
      aws cloudfront create-invalidation --distribution-id ${module.cloudfront.cloudfront_distribution_id} --paths "/*"
    EOT
  }

  depends_on = [module.cloudfront] # ✅ Correct dependency (module-based)
}
