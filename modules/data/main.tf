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
  amzn_ami     = one(data.aws_ami.amzn_linux[*].id)
  ubuntu_ami   = one(data.aws_ami.ubuntu[*].id)
  cloud_config = [for v in data.template_cloudinit_config.cloud_config : v.rendered]
}

data "template_file" "cloud_config" {
  count    = length(var.instance_hostnames) > 0 ? length(var.instance_hostnames) : 0
  template = file("${path.module}/cloud-config.yaml")

  vars = {
    hostname        = var.instance_hostnames[count.index]
    ssh_key_name    = var.key_name
    public_ssh_key  = file("${var.priv_key_path}/${var.key_name}.pub")
    private_ssh_key = file("${var.priv_key_path}/${var.key_name}")
  }
}

data "template_cloudinit_config" "cloud_config" {
  count         = length(data.template_file.cloud_config) > 0 ? length(data.template_file.cloud_config) : 0
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_config[count.index].rendered
  }
}
