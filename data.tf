data "aws_ami" "amzn2_linux" {
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

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-disco-19.04-amd64*"]
  }
}

data "template_file" "cloud_config" {
  template = file("${path.module}/cloud-config.tpl")

  vars = {
    ssh_key = data.local_file.ssh_key.content
  }
}

data "local_file" "ssh_key" {
  filename = pathexpand(var.priv_ssh_key_path)
}
