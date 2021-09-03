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
  s3_endpoint_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowYumRepos",
        "Principal" : "*",
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::packages.${data.aws_region.this.name}.amazonaws.com/*",
          "arn:aws:s3:::repo.${data.aws_region.this.name}.amazonaws.com/*",
          "arn:aws:s3:::amazonlinux.${data.aws_region.this.name}.amazonaws.com/*"
        ]
      }
    ]
  })
}

### -------------------------------------------------------------------------------------------- ###
### THERE'S A BUG HERE, NEED TO INVESTIGATE AND REPORT
### POLLICY MENTIONES THAT CAN'T ADD PRINCIPALS BUT AWS POLICY REQUIRES IT
### -------------------------------------------------------------------------------------------- ###
data "aws_iam_policy_document" "s3_endpoint_policy" {
  statement {
    sid     = "AllowYumRepoAccess"
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      "arn:aws:s3:::packages.${data.aws_region.this.name}.amazonaws.com/*",
      "arn:aws:s3:::repo.${data.aws_region.this.name}.amazonaws.com/*",
      "arn:aws:s3:::amazonlinux.${data.aws_region.this.name}.amazonaws.com/*"
    ]
  }
}

resource "aws_iam_policy" "s3_endpoint_policy" {
  name   = "s3_endpoint_policy"
  policy = data.aws_iam_policy_document.s3_endpoint_policy.json
}
### -------------------------------------------------------------------------------------------- ###

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
