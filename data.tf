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
    values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server*"]
  }
}

data "template_file" "cloud_config" {
  count    = length(var.hostnames)
  template = file("${path.module}/cloud-config.tpl")

  vars = {
    hostname = var.hostnames[count.index]
    ssh_key  = data.local_file.ssh_key.content
  }
}

data "local_file" "ssh_key" {
  filename = pathexpand(var.priv_ssh_key_path)

  depends_on = [
    aws_key_pair.aws_test_key
  ]
}
