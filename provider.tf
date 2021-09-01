locals {
  aws_profile = var.aws_profile.sandbox
}
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = var.credentials_file
  profile                 = local.aws_profile

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
      Region      = "US-East-1"
    }
  }
}

provider "aws" {
  alias                   = "us_east_1"
  region                  = "us-east-1"
  shared_credentials_file = var.credentials_file
  profile                 = local.aws_profile

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
      Region      = "US-East-1"
    }
  }
}

provider "aws" {
  alias                   = "us_west_2"
  region                  = "us-west-2"
  shared_credentials_file = var.credentials_file
  profile                 = local.aws_profile

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
      Region      = "US-West-2"
    }
  }
}
