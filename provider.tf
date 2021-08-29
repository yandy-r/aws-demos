provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.credentials_file
  profile                 = var.aws_profile.sandbox

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = var.owner
    }
  }
}
