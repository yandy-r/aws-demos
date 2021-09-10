variable "priv_key_path" {
  type = string
}

variable "key_name" {
  type = string
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = "4096"

  provisioner "local-exec" {
    command = "echo '${tls_private_key.this.private_key_pem}' > ${var.priv_key_path}/${var.key_name}"
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.this.public_key_openssh}' > ${var.priv_key_path}/${var.key_name}.pub"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.priv_key_path}/${var.key_name}"
  }
  provisioner "local-exec" {
    command = "chmod 600 ${var.priv_key_path}/${var.key_name}.pub"
  }
}

output "ssh_public_key" {
  value     = tls_private_key.this.public_key_openssh
  sensitive = true
}
