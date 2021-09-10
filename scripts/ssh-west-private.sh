#!/bin/bash

WEST_BASTION="$(jq -r '.resources[] |
select(.name == "this") |
select(.type == "aws_instance") |
select(.module == "module.west_ec2") |
.instances[0].attributes.private_ip' <terraform.tfstate)"

echo "Remoting into ${WEST_BASTION}"
ssh -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i ${HOME}/.aws-keys/aws-test-key \
  cloud-useer@"${WEST_BASTION}"
