```terraform
provider "aws" {
  region = "us-east-1" # Or your desired AWS region
}

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# AWS VPC Module
# Creates a VPC with public and private subnets, NAT Gateway, etc.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Use a specific version for production

  name = "my-application-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"] # Adjust AZs based on your region
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # For cost savings in development/testing

  tags = {
    Environment = "Dev"
    Project     = "MyWebApp"
  }
}

# Security Group for the EC2 Instance
# Allows SSH access from anywhere (0.0.0.0/0) - restrict in production!
resource "aws_security_group" "ec2_sg" {
  name        = "my-app-ec2-sg"
  description = "Allow SSH inbound traffic to EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world. Restrict to specific IPs/CIDRs in production.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "my-app-ec2-sg"
  }
}

# Placeholder for SSH Key Pair
# IMPORTANT: Replace the dummy public_key with your actual SSH public key content.
# This key is required to SSH into the EC2 instance.
resource "aws_key_pair" "deployer" {
  key_name   = "my-ec2-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3b+x0l6S+k6N0c6X3Z6F5V4G2l9M3Y3k5l7f8M9k2n1o1v0s8h7j6i5u4t3r2q1p0o9n8m7l6k5j4i3h2g1f0e9d8c8b7a6s5d4f3g2h1j0k9l8m7n6o5p4q3r2s1t0u9v8w7x6y5z5y4x3w2v1u0t9s8r7q6p5o4n3m2l1k0j9i8h7g6f5e4d3c2b1a0s9d8f7g6h5j4k3l2m1n0o9p8q7r2s1t0u9v8w7x6y5z your_email@example.com"
  # For example: `file("~/.ssh/id_rsa.pub")` if running locally and the file exists.
}


# AWS EC2 Instance Module
# Creates a single EC2 instance in a public subnet of the VPC
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0" # Use a specific version for production

  name                   = "my-application-instance"
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.amazon_linux.id
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = module.vpc.public_subnets[0] # Launch in the first public subnet

  tags = {
    Environment = "Dev"
    Project     = "MyWebApp"
  }
}

# Output Block
# These outputs provide useful information after Terraform applies the configuration
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets in the VPC"
  value       = module.vpc.public_subnets
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = module.ec2_instance.public_dns
}
```