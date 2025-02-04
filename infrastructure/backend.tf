# terraform backend state
terraform {
  backend "s3" {
    bucket  = "terraform-state-gbvcdu43"
    key     = "stage/state"
    encrypt = true
  }
}
