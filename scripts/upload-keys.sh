#!/bin/bash

# shellcheck disable=SC1004
# UPLOAD WEST KEY TO EAST HUB

EAST_BASTION="$(jq -r '.resources[] |
select(.name == "hub_public") |
select(.type == "aws_instance") |
select(.module == "module.tgw_east") |
.instances[0].attributes.public_ip' <terraform.tfstate)"

scp -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-east-1-test-key \
  keys/aws-us-west-2-test-key \
  ec2-user@"${EAST_BASTION}":.ssh/west-key

ssh -T -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-east-1-test-key \
  ec2-user@"${EAST_BASTION}" \
  'for i in "10.200.128.10" "10.201.128.10" "10.202.128.10" "10.203.128.10"; do \
  scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
  -i .ssh/ssh-key .ssh/west-key ec2-user@${i}:.ssh/
  done'

# UPLOAD EAST KEY TO WEST HUB

WEST_BASTION="$(jq -r '.resources[] |
select(.name == "hub_public") |
select(.type == "aws_instance") |
select(.module == "module.tgw_west") |
.instances[0].attributes.public_ip' <terraform.tfstate)"

scp -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-west-2-test-key \
  keys/aws-us-east-1-test-key \
  ec2-user@"${WEST_BASTION}":.ssh/east-key

ssh -T -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-west-2-test-key \
  ec2-user@"${WEST_BASTION}" \
  'for i in "10.220.128.10" "10.221.128.10" "10.222.128.10" "10.223.128.10"; do \
  scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
  -i .ssh/ssh-key .ssh/east-key ec2-user@${i}:.ssh/
  done'
