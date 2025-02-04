# terraform backend state
terraform {
  backend "s3" {
    bucket  = "terraform-state-gbvcdu43"
    key     = "pipeline/state"
    encrypt = true
  }
}
