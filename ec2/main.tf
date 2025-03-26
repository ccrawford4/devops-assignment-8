provider "aws" {
  region = var.aws_region
}

resource "random_string" "random" {
  length = 8
  special = false 
  upper = false
}

locals {
  unique_ami_name = "${var.ami_name}-${random_string.random.id}"
  unique_key_name = "${var.ssh_keypair_name}-${random_string.random.id}"
}

# Generate private key
resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Save private key to file
resource "local_file" "private_key" {
  content = tls_private_key.ec2_ssh_key.private_key_pem
  filename = "${path.module}/${local.unique_key_name}.pem"
  file_permission = "0600"
}

# Export public key to file for Packer
resource "local_file" "public_key" {
  content = tls_private_key.ec2_ssh_key.public_key_openssh
  filename = "${path.module}/${local.unique_key_name}.pub"
}

# Export the public key to EC2
resource "aws_key_pair" "generated_key" {
  key_name = local.unique_key_name
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh
}


# Create the AMI from packer
resource "null_resource" "packer" {
  triggers = {
    packer_file = sha1(file("${path.module}/build.pkr.hcl"))
    public_key = tls_private_key.ec2_ssh_key.public_key_openssh
  }
  
  provisioner "local-exec" {
    working_dir = path.module
    command     = <<EOT
packer build \
-var "aws_region=${var.aws_region}" \
-var "ami_name=${local.unique_ami_name}" \
-var "instance_type=${var.instance_type}" \
-var "ssh_username=${var.ssh_username}" \
-var "ssh_keypair_name=${local.unique_key_name}" \
-var "ssh_public_key_file=${local.unique_key_name}.pub" \
build.pkr.hcl
EOT
  }
}

# Create the bastion host security group
resource "aws_security_group" "aws_ec2_security_group" {
  name = "public-ec2-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Look up the AMI by name
data "aws_ami" "instance" {
  depends_on = [null_resource.packer]
  most_recent = true
  owners = ["self"]
  
  filter {
    name = "name"
    values = ["${var.ami_name}*"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}

# Create the Bastion Host
resource "aws_instance" "ec2" {
  count = 6
  associate_public_ip_address = true
  ami = data.aws_ami.instance.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.aws_ec2_security_group.id]
  subnet_id = var.public_subnet_id
  key_name = aws_key_pair.generated_key.key_name

  tags = {
    Name = "bastion-host"
  }
}
