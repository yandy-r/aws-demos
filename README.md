This deploys the infrastructure depicted in this diagram.

[![Transit Gateway Deployment](images/aws-transit-gateway-demo-hub-spoke-800.png)](images/aws-transit-gateway-demo-hub-spoke.png)

## Terraform

Make sure you have `Terraform version 0.12.[x]` installed, at the time of this writting `0.12` is at release candidate 1.

## Deploy

Make sure you have an AWS environment setup, the AWS CLI configured or environment variables with appropriate keys.

### Clone

`git clone https://github.com/IPyandy/aws-transit-gateway-demo.git`

### Plan and Deploy

```shell
cd aws-transit-gateway-demo

terraform init
terraform plan -o plan.tfplan
terraform apply plan.tfplan
```
