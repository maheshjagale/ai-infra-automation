```terraform
# Configure the AWS provider
provider "aws" {
  region = "us-east-1" # Making a reasonable assumption for the AWS region
}

# Data source to get the latest Amazon Linux 2 AMI
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

# Resource: AWS VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Resource: AWS Subnet (Public Subnet)
# Making a reasonable assumption for subnet details (name, CIDR, AZ)
resource "aws_subnet" "main_public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${data.aws_ami.amazon_linux_2.architecture == "x86_64" ? "us-east-1a" : "us-east-1a"}" # Assuming us-east-1a for x86_64
  map_public_ip_on_launch = true # Required for EC2 instance to get a public IP

  tags = {
    Name = "main-public-subnet-1"
  }
}

# Resource: AWS Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# Resource: AWS Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"        # Default route for all outbound traffic
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Resource: AWS Route Table Association
resource "aws_route_table_association" "main_subnet_association" {
  subnet_id      = aws_subnet.main_public_subnet_1.id
  route_table_id = aws_route_table.main_route_table.id
}

# Resource: AWS Security Group for EC2
resource "aws_security_group" "web_server_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "web-server-sg"
  description = "Allow SSH, HTTP, HTTPS inbound traffic"

  # Ingress rules for specified ports
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (for demonstration)
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
    description = "HTTPS access"
  }

  # Egress rule (allowing all outbound traffic by default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Resource: AWS EC2 Instance
resource "aws_instance" "web_server_1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main_public_subnet_1.id
  # Associate the security group with the EC2 instance
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  # User data to install a basic web server (Apache)
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from ${aws_instance.web_server_1.tags.Name} running on Amazon Linux 2!</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-1"
  }
}

# Output the public IP address of the EC2 instance
output "web_server_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_instance.web_server_1.public_ip
}

# Output the public DNS name of the EC2 instance
output "web_server_public_dns" {
  description = "The public DNS name of the web server"
  value       = aws_instance.web_server_1.public_dns
}

# Output the VPC ID
output "vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.main_vpc.id
}

# Output the Subnet ID
output "subnet_id" {
  description = "The ID of the main public subnet"
  value       = aws_subnet.main_public_subnet_1.id
}
```