<p align="center">
<img src="https://static-00.iconduck.com/assets.00/terraform-icon-1803x2048-hodrzd3t.png" width="128"/>
</p>

<h3 align="center">Infrastructure Code for nbaplaydb.com</h3>

This repository is Terraform Infrastructure-as-Code codebase to create required infrastructure for [nbaplaydb.com](nbaplaydb.com)

For required variables, see [terraform.tfvars](terraform.tfvars) file.

### Prerequisites

1. Configure the AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
2. Terraform installation (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Action

Plan to see which resources will be created:

```
terraform plan
```

Create all resources on your account:

```
terraform apply
```
