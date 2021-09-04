#!/bin/bash

EAST_BASTION="$(jq -r '.resources[] |
select(.name == "this") |
select(.type == "aws_instance") |
select(.module == "module.east_ec2") |
.instances[0].attributes.public_ip' <terraform.tfstate)"

ssh -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i "${HOME}"/.aws-keys/aws-test-key \
  ec2-user@"${EAST_BASTION}"
