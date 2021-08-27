provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "acg-sandbox"

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Yandy"
    }
  }
}
