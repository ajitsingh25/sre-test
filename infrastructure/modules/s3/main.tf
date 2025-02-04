# ✅ Generate Random Suffix for Bucket Uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# ✅ Create S3 Bucket for Static Website Hosting
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.3.0"

  bucket = "${var.bucket_name}-${random_string.suffix.result}"

  #   website = null

  versioning = {
    enabled = true
  }

  force_destroy = true
}

# ✅ Secure S3 Bucket with Ownership Controls
resource "aws_s3_bucket_ownership_controls" "frontend_bucket_ownership" {
  bucket = module.s3_bucket.s3_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ✅ Block Public Access for S3
resource "aws_s3_bucket_public_access_block" "frontend_bucket_block" {
  bucket = module.s3_bucket.s3_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle {
    ignore_changes = [block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets]
  }
}

# ✅ Secure S3 Bucket with CloudFront Access Policy
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  count  = var.enable_s3_config ? 1 : 0 # ✅ Creates only if enabled
  bucket = module.s3_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnforceHTTPS",
      Effect    = "Deny",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${module.s3_bucket.s3_bucket_arn}/*",
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
      },
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${module.s3_bucket.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
    }]
  })

  depends_on = [module.s3_bucket]
}

# ✅ Replace API Gateway URL in index.html before uploading to S3
resource "null_resource" "update_index_html" {
  count = var.enable_s3_config ? 1 : 0 # ✅ Creates only if enabled

  triggers = {
    api_url   = var.api_gateway_url                            # ✅ Track API Gateway URL changes
    file_hash = filemd5("${path.root}/../frontend/index.html") # ✅ Track index.html changes
  }

  provisioner "local-exec" {
    command = <<EOT
      cp ${path.root}/../frontend/index.html ${path.root}/../frontend/index_updated.html
    #   sed -i 's|__API_BASE_URL__|${var.api_gateway_url}|g' ${path.root}/../frontend/index_updated.html
      sed -i '' 's|__API_BASE_URL__|${var.api_gateway_url}|g' ${path.root}/../frontend/index_updated.html
    EOT
  }
}

# ✅ Upload updated index.html to S3 bucket
resource "aws_s3_object" "index_html" {
  count        = var.enable_s3_config ? 1 : 0 # ✅ Creates only if enabled
  bucket       = module.s3_bucket.s3_bucket_id
  key          = "index.html"
  source       = "${path.root}/../frontend/index_updated.html" # ✅ Upload the modified file
  content_type = "text/html"

  depends_on = [null_resource.update_index_html] # ✅ Ensure replacement is done before upload

  lifecycle {
    replace_triggered_by = [null_resource.update_index_html]
  }
}
