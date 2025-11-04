```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- VPC (Virtual Private Cloud) ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# --- Internet Gateway for public connectivity ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# --- Public Subnet ---
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${aws_vpc.main.region}a" # Use the first AZ in the selected region

  tags = {
    Name = "public-subnet"
  }
}

# --- Route Table for public subnet ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# --- Associate Route Table with public subnet ---
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group for the EC2 instance ---
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-instance-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: 0.0.0.0/0 allows access from anywhere. Restrict this in production.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-instance-security-group"
  }
}

# --- Data source to get the latest Amazon Linux 2 AMI ---
data "aws_ami" "amazon_linux_2" {
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

# --- Key Pair for SSH access ---
resource "tls_private_key" "rsa_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-generated-key"
  public_key = tls_private_key.rsa_key_pair.public_key_openssh
}

# --- EC2 Instance ---
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro" # Free tier eligible instance type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true # Assign a public IP for direct internet access

  tags = {
    Name = "web-server-instance"
  }
}

# --- Output the generated private key for SSH access ---
output "private_key" {
  description = "The private key for SSH access to the EC2 instance. Save this securely."
  value       = tls_private_key.rsa_key_pair.private_key_pem
  sensitive   = true # Mark as sensitive to prevent accidental logging
}

# --- Output the public IP address of the EC2 instance ---
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

# --- Output the SSH command to connect to the instance ---
output "ssh_command" {
  description = "SSH command to connect to the EC2 instance. Remember to chmod 400 your_key.pem"
  value       = "ssh -i YOUR_PRIVATE_KEY_FILE.pem ec2-user@${aws_instance.web_server.public_ip}"
}
```