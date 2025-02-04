output "git_personal_token" {
  description = "Git Personal Access Token from AWS Secrets Manager"
  value       = jsondecode(data.aws_secretsmanager_secret_version.git_secret_value.secret_string)["token"]
  sensitive   = true # ✅ Marks as sensitive to avoid accidental exposure
}