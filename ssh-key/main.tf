variable "priv_ssh_key_path" {
  type = string
}

variable "key_name" {
  type = string
}

resource "tls_private_key" "aws_test_priv_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"

  provisioner "local-exec" {
    command = "echo '${tls_private_key.aws_test_priv_key.private_key_pem}' > ${var.priv_ssh_key_path}/${var.key_name}"
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.aws_test_priv_key.public_key_openssh}' > ${var.priv_ssh_key_path}/${var.key_name}.pub"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.priv_ssh_key_path}/${var.key_name}"
  }
  provisioner "local-exec" {
    command = "chmod 600 ${var.priv_ssh_key_path}/${var.key_name}.pub"
  }
}

output "priv_key" {
  value     = tls_private_key.aws_test_priv_key
  sensitive = true
}
