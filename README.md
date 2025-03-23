# AWS Infrastructure using Terraform

## About
This Terraform module provisions a secure AWS environment with the following components:
* **VPC**
* **Bastion Host (EC2 Instance)**
  * Within the VPC in public subnet
  * SSH (22) ingress traffic from client IP address only
  * Unrestricted egress traffic
* **Private Server (EC2 Instance)**
  * Within VPC in private subnet
  * Configure number of instances created using the `instance_count` variable
  * SSH (22) ingress traffic from bastion host IP address only
  * Unrestricted egress traffic
  
## Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) >= v1.10.5
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) >= 2.18.5

## Installation

1. Clone the repository
   ```bash
   # Using HTTPS
   git clone https://github.com/ccrawford4/oneflow-infra.git
   
   # Or using SSH
   git clone git@github.com:ccrawford4/oneflow-infra.git
   ```

2. Navigate to the repository directory
   ```bash
   cd oneflow-infra
   ```

## Environment Configuration

1. Create your `secrets.auto.tfvars` file
   ```bash
   cp secrets.auto.tfvars.example secrets.auto.tfvars
   ```

2. Edit the `secrets.auto.tfvars` file with your configuration values:
   ```terraform
   environment = "<environment name>"  # dev or prod
   aws_account_id = "<aws account id>"
   db_username = "<database username>"
   db_password = "<database password>"
   db_name = "<database name>"
   db_port = <database port>
   ```

3. Configure AWS CLI with your AWS credentials
   ```bash
   aws configure
   ```

## Infrastructure Deployment
1. Initialize the backend
```bash
terraform init
```
2. Run terraform plan
```bash
terraform plan
```
3. Run terraform apply
```bash
terraform apply
```

## Testing
