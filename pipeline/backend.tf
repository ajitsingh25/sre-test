# terraform backend state
terraform {
  backend "s3" {
    bucket  = "ajitsre-qu6gcg2w"
    key     = "pipeline/state"
    encrypt = true
  }
}
