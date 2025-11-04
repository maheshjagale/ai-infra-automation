```terraform
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Making a reasonable assumption for the AWS region
}

# 1. VPC Creation
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true # Recommended for most VPCs

  tags = {
    Name = "main-vpc"
  }
}

# 2. Subnet Creation
# Creating two public subnets for high availability, one in each of two AZs.
# Making a reasonable assumption for subnet CIDRs and AZs as they were not specified.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "main_public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # Required for instances to get public IPs

  tags = {
    Name = "main-public-subnet-1"
  }
}

resource "aws_subnet" "main_public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true # Required for instances to get public IPs

  tags = {
    Name = "main-public-subnet-2"
  }
}

# 3. Internet Gateway Creation
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# 4. Route Table Creation and Association
resource "aws_route_table" "main_public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main-public-route-table"
  }
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "main_public_subnet_1_association" {
  subnet_id      = aws_subnet.main_public_subnet_1.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_route_table_association" "main_public_subnet_2_association" {
  subnet_id      = aws_subnet.main_public_subnet_2.id
  route_table_id = aws_route_table.main_public_route_table.id
}

# 5. Security Group Creation
resource "aws_security_group" "web_server_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "web-server-sg"
  description = "Allow SSH, HTTP, HTTPS, MySQL inbound traffic"

  # Ingress rules for specified ports
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (for demonstration purposes, restrict in production)
    description = "Allow SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
    description = "Allow HTTPS"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow MySQL/Aurora from anywhere (for demonstration purposes, restrict in production)
    description = "Allow MySQL"
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# 6. EC2 Instance Creation
# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server_1" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main_public_subnet_1.id # Deploying in the first public subnet
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  # For demonstration, a key pair is not included, but it is highly recommended for production
  # key_name = "your-key-pair-name"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Terraform deployed EC2!</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-1"
  }
}

# Optional: Output the public IP of the EC2 instance
output "web_server_public_ip" {
  description = "The public IP address of the web server instance."
  value       = aws_instance.web_server_1.public_ip
}

output "web_server_public_dns" {
  description = "The public DNS name of the web server instance."
  value       = aws_instance.web_server_1.public_dns
}
```