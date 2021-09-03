### -------------------------------------------------------------------------------------------- ###
### VERSIONS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.56"
    }
  }
}

data "aws_region" "this" {}

locals {
  s3_endpoint_policy = jsondecode(data.template_file.s3_endpoint_policy.rendered)
}
data "template_file" "s3_endpoint_policy" {
  template = file("${path.module}/s3_endpoint_policy.json")

  vars = {
    region = data.aws_region.this.name
  }
}

# data "aws_ami" "amzn2_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm*"]
#   }

#   filter {
#     name   = "state"
#     values = ["available"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"]

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server*"]
#   }
# }

# data "template_file" "cloud_config" {
#   count    = length(var.hostnames)
#   template = file("${path.module}/cloud-config.tpl")

#   vars = {
#     hostname = var.hostnames[count.index]
#     ssh_key  = data.local_file.ssh_key.content
#   }
# }

# data "local_file" "ssh_key" {
#   filename = pathexpand("${var.priv_key_path}/${aws_key_pair.this.key_name}")

#   depends_on = [
#     aws_key_pair.this
#   ]
# }
