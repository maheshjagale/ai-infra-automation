```terraform
provider "aws" {
  region = "us-east-1" # Or your preferred region
}

resource "aws_key_pair" "ec2_ssh_key" {
  key_name   = "my-ec2-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsFq... your_public_key_here user@hostname" # Replace with your actual public key content
}

resource "aws_security_group" "ec2_ssh_security_group" {
  name        = "ec2-ssh-access"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: 0.0.0.0/0 allows access from any IP. Restrict this in a production environment.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2 SSH Access"
  }
}

data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "my_ec2_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_ssh_security_group.id]

  tags = {
    Name        = "MyAmazonLinux2Instance"
    Environment = "Development"
    Owner       = "DevOpsTeam"
  }
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.my_ec2_instance.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.my_ec2_instance.public_dns
}
```