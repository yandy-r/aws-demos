provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = var.credentials_file
  profile                 = var.aws_profile.sandbox

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
    }
  }
}

provider "aws" {
  alias                   = "west"
  region                  = "us-west-2"
  shared_credentials_file = var.credentials_file
  profile                 = var.aws_profile.sandbox

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
    }
  }
}
