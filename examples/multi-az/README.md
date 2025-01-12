# Wireguard multi AZ deployment
This setup provides high availability within a single AWS region, utilizing multiple availability zones.

## Design
![Wireguard Multi AZ design](./../../docs/aws-wireguard-multi-az-no-app.png)

### Clients connections
Multiple EC2 instances are spread across several availability zones within a region. Clients connections get distributed to the instances through highly-available Network Load Balancer with Route53 DNS record attached (optional).

### Configuration changes
Wireguard configuration file is being generated by Terraform and stored in S3 bucket with enabled versioning and access logs. Every S3 bucket content change triggers Lambda function through SQS queue. Lambda function executes predefined SSM document on all Wireguard EC2 instances. SSM document is configured to upload the latest configuration file to the instances and reload Wireguard interface.
Also, Wireguard instances have PreUp hook enabled which additionally ensures that they use the latest configuration file available in S3.

## Requirements
| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.44.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.1.0 |
| <a name="requirement_wireguard"></a> [wireguard](#requirement\_wireguard) | 0.1.3 |

## Quick start
The code supports both `terraform` and `terragrunt`. In case of pure `terraform` state file will be stored locally but if you prefer `teragrant`, S3 bucket for the state will be created automatically on your behalf.

### Set variables
Please, review defined variables under `terraform.tvars` file. For simplicity, this example doesn't redefine all defaults provided by the module.
The whole list of available variables is presented in module [README.md](./../../README.md) file.

#### Wireguard clients
Wireguard clients are managed by `wg_peers` variable. Example:
```hcl
wg_peers = {
  user-1 = {
    public_key      = "dRWcZBv2++23GZ0DdoFLrXvGch4lcZ2Fj7yeaSAUB2I="
    peer_ip         = "10.0.44.2/32"
    allowed_subnets = ["10.0.44.0/24", "8.8.8.8/32"]
    isolated        = true
  }
  user-2 = {
    public_key      = ""
    peer_ip         = "10.0.44.3/32"
    allowed_subnets = ["10.0.44.0/24", "8.8.8.8/32"]
    isolated        = true
  }
}
```
* `public_key` — peer public key. It is optional and will be automatically generated if empty string passed.
* `peer_ip` — peer IP-address or subnet in CIDR notation. Must be within `wg_cidr` range.
* `allowed_subnets` — controls what subnets peer will be able to access through Wireguard network (for bounce server mode set to `0.0.0.0/0`).
* `isolated` — if `true` peer won't be able to access other Wireguard peers.

If you already have Wireguard installed, you may generate all the keys yourself and pass them through variables:
```shell
umask 077 ; wg genkey > privatekey ; wg pubkey < privatekey > publickey
```

#### DNS
If your target DNS zone is managed by Route53, this code may create a DNS record for Wireguard endpoint for you.
Make sure that you define your domain zone name in `dns_zone_name` variable in `terraform.tfvars` file.
This is optional, if that variable is omitted or empty string passed, the code will skip Route53 resources.

#### SSH key pair
Please, define your SSH public key in `ec2_ssh_public_key` variable. That key will be used for EC2 instances.

### AWS connection
Before running the code, make sure that your AWS connection is working.
```shell
aws sts get-caller-identity
```
If you're using `aws-vault` tool, see examples below.

### Deploy Wireguard server
Several ways of deployment will be presented below. Please, choose the one which fits your needs best.
Before proceeding make sure that `AWS_REGION` variable is set correctly.
```shell
export AWS_REGION=<YOUR REGION>
```
#### Terragrunt how-to
```shell
cd examples/multi-az
terragrunt init
terragrunt plan
terragrunt apply

# get wireguard keys after deployment
terragrunt output wireguard_server_keys

# get wireguard generated client keys after deployment
terragrunt output wireguard_client_generated_keys

# get wireguard client configuration files after deployment
terragrunt output wireguard_client_configs
```

#### Terragrunt with aws-vault how-to
```shell
cd examples/multi-az
aws-vault exec $AWS_PROFILE --no-session -- terragrunt init
aws-vault exec $AWS_PROFILE --no-session -- terragrunt plan
aws-vault exec $AWS_PROFILE --no-session -- terragrunt apply

# get wireguard keys after deployment
aws-vault exec $AWS_PROFILE --no-session -- terragrunt output wireguard_server_keys

# get wireguard generated client keys after deployment
aws-vault exec $AWS_PROFILE --no-session -- terragrunt output wireguard_client_generated_keys

# get wireguard client configuration files after deployment
aws-vault exec $AWS_PROFILE --no-session -- terragrunt output wireguard_client_configs
```

#### Terraform how-to
```shell
cd examples/multi-az
terraform init
terraform plan
terraform apply

# get wireguard keys after deployment
terraform output wireguard_server_keys

# get wireguard generated client keys after deployment
terraform output wireguard_client_generated_keys

# get wireguard client configuration files after deployment
terraform output wireguard_client_configs
```

#### Terraform with aws-vault how-to
```shell
cd examples/multi-az
aws-vault exec $AWS_PROFILE --no-session -- terraform init
aws-vault exec $AWS_PROFILE --no-session -- terraform plan
aws-vault exec $AWS_PROFILE --no-session -- terraform apply

# get wireguard keys after deployment
aws-vault exec $AWS_PROFILE --no-session -- terraform output wireguard_server_keys

# get wireguard generated client keys after deployment
aws-vault exec $AWS_PROFILE --no-session -- terraform output wireguard_client_generated_keys

# get wireguard client configuration files after deployment
aws-vault exec $AWS_PROFILE --no-session -- terraform output wireguard_client_configs
```

## Resources
| Name | Type |
|------|------|
| [aws_key_pair.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [random_pet.main](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [wireguard_asymmetric_key.wg_key_pair](https://registry.terraform.io/providers/OJFord/wireguard/0.1.3/docs/resources/asymmetric_key) | resource |
| [wireguard_asymmetric_key.wg_key_pair_clients](https://registry.terraform.io/providers/OJFord/wireguard/0.1.3/docs/resources/asymmetric_key) | resource |
| [aws_availability_zones.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Number of availability zones to create VPC subnets in | `string` | n/a | yes |
| <a name="input_dns_zone_name"></a> [dns\_zone\_name](#input\_dns\_zone\_name) | Route53 DNS zone name for Wireguard server endpoint. If not set, AWS LB DNS record is used | `string` | `""` | no |
| <a name="input_ec2_ssh_public_key"></a> [ec2\_ssh\_public\_key](#input\_ec2\_ssh\_public\_key) | EC2 SSH public key | `string` | n/a | yes |
| <a name="input_s3_bucket_name_prefix"></a> [s3\_bucket\_name\_prefix](#input\_s3\_bucket\_name\_prefix) | Prefix to be added to S3 bucket name | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | AWS desired VPC CIDR | `string` | n/a | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_vpc\_private\_subnets) | VPC private subnets CIDR to create EC2 instances in. AZs of public & private subnets must match | `list(string)` | n/a | yes |
| <a name="input_vpc_public_subnets"></a> [vpc\_public\_subnets](#input\_vpc\_public\_subnets) | VPC public subnets CIDR to create NLB in. Multiple subnets are used for HA. AZs of public & private subnets must match | `list(string)` | n/a | yes |
| <a name="input_wg_allow_connections_from_subnets"></a> [wg\_allow\_connections\_from\_subnets](#input\_wg\_allow\_connections\_from\_subnets) | Allow inbound connections to Wireguard server from these networks. To allow all networks set to `0.0.0.0/0` | `list(string)` | n/a | yes |
| <a name="input_wg_peers"></a> [wg\_peers](#input\_wg\_peers) | Wireguard clients (peers) configuration. `Public_key` is optional — will be automatically generated if empty. `Peer_ip` — desired client IP-address or subnet in CIDR notation within Wireguard network (must be within `wg_cidr` range). `Allowed_subnets` — controls what subnets peer will be able to access through Wireguard network (for bounce server mode set to `0.0.0.0/0`). `Isolated` — if `true` peer won't be able to access other Wireguard peers. | `map(object({ public_key = string, peer_ip = string, allowed_subnets = list(string), isolated = bool }))` | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | EC2 autoscaling group ARN |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | EC2 autoscaling group name |
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | ARN of IAM instance profile to access S3 bucket |
| <a name="output_iam_instance_profile_id"></a> [iam\_instance\_profile\_id](#output\_iam\_instance\_profile\_id) | ID of IAM instance profile to access S3 bucket |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of IAM role to access S3 bucket |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of IAM role to access S3 bucket |
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | EC2 launch template ARN |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | EC2 launch template ID |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | Load balancer ARN |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | Load balancer DNS name |
| <a name="output_s3_bucket_access_logs_arn"></a> [s3\_bucket\_access\_logs\_arn](#output\_s3\_bucket\_access\_logs\_arn) | Load balancer access logs S3 bucket ARN |
| <a name="output_s3_bucket_access_logs_name"></a> [s3\_bucket\_access\_logs\_name](#output\_s3\_bucket\_access\_logs\_name) | Load balancer access logs S3 bucket name |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | Wireguard configuration S3 bucket ARN |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Wireguard configuration S3 bucket name |
| <a name="output_sqs_queue_arn"></a> [sqs\_queue\_arn](#output\_sqs\_queue\_arn) | SQS queue for S3 notifications ARN |
| <a name="output_sqs_queue_dead_letter_arn"></a> [sqs\_queue\_dead\_letter\_arn](#output\_sqs\_queue\_dead\_letter\_arn) | SQS dead letter queue for S3 notifications ARN |
| <a name="output_sqs_queue_dead_letter_id"></a> [sqs\_queue\_dead\_letter\_id](#output\_sqs\_queue\_dead\_letter\_id) | SQS dead letter queue for S3 notifications ID |
| <a name="output_sqs_queue_id"></a> [sqs\_queue\_id](#output\_sqs\_queue\_id) | SQS queue for S3 notifications ID |
| <a name="output_wireguard_client_configs"></a> [wireguard\_client\_configs](#output\_wireguard\_client\_configs) | Example configuration files for Wireguard clients |
| <a name="output_wireguard_client_generated_keys"></a> [wireguard\_client\_generated\_keys](#output\_wireguard\_client\_generated\_keys) | Wireguard client public & private keys |
| <a name="output_wireguard_server_endpoints"></a> [wireguard\_server\_endpoints](#output\_wireguard\_server\_endpoints) | Wireguard server endpoints |
| <a name="output_wireguard_server_host"></a> [wireguard\_server\_host](#output\_wireguard\_server\_host) | Wireguard server host |
| <a name="output_wireguard_server_keys"></a> [wireguard\_server\_keys](#output\_wireguard\_server\_keys) | Wireguard public & private keys |
| <a name="output_wireguard_server_name"></a> [wireguard\_server\_name](#output\_wireguard\_server\_name) | Wireguard server name |
| <a name="output_wireguard_server_ports"></a> [wireguard\_server\_ports](#output\_wireguard\_server\_ports) | Wireguard server ports |

## Contribute
Any reasonable pull requests are always welcomed. All PRs are subject to automated checks, so please make sure that your changes pass all configured [pre-commit](https://pre-commit.com/) hooks.
If you found a bug or need support of any kind, please start a new conversation in [Issues](https://github.com/Globaldots/tf-wireguard-server/issues) section. 

## License
The code is licensed under GNU GPL [license](./../../LICENSE).
