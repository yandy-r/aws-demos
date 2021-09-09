output "s3_endpoint_policy" {
  value = local.s3_endpoint_policy
}

output "amzn_ami" {
  value = local.amzn_ami
}

output "ubuntu_ami" {
  value = local.ubuntu_ami
}

output "cloud_config" {
  value = local.cloud_config[*]
}
