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
          "arn:aws:s3:::amazonlinux-2-repos-${data.aws_region.this.name}/*"
        ]
      }
    ]
  })
}

### -------------------------------------------------------------------------------------------- ###

data "aws_ami" "amzn_linux" {
  count       = var.get_amzn_ami ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "ubuntu" {
  count       = var.get_ubuntu_ami ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server*"]
  }
}

locals {
  amzn_ami            = one(data.aws_ami.amzn_linux[*].id)
  ubuntu_ami          = one(data.aws_ami.ubuntu[*].id)
  amzn_cloud_config   = [for v in data.template_file.amzn_cloud_config : base64encode(v.rendered)]
  ubuntu_cloud_config = [for v in data.template_file.ubuntu_cloud_config : base64encode(v.rendered)]
}

data "template_file" "amzn_cloud_config" {
  count    = length(var.instance_hostnames) > 0 && var.get_amzn_ami ? length(var.instance_hostnames) : 0
  template = file("${path.module}/amzn-cloud-config.tpl")

  vars = {
    hostname = var.instance_hostnames[count.index]
    ssh_key  = data.local_file.ssh_key.content
  }
}

data "template_file" "ubuntu_cloud_config" {
  count    = length(var.instance_hostnames) > 0 && var.get_ubuntu_ami ? length(var.instance_hostnames) : 0
  template = file("${path.module}/ubuntu-cloud-config.tpl")

  vars = {
    hostname = var.instance_hostnames[count.index]
    ssh_key  = data.local_file.ssh_key.content
  }
}

data "local_file" "ssh_key" {
  filename = pathexpand("${var.priv_key_path}/${var.key_name}")
}
