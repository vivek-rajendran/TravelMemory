terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Dynamic AMI lookup for Canonical Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's Official AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("~/.ssh/travelmemory-key.pub")
}

# ------------------------------------------------------------------------------
# IAM Role and Instance Profile for EC2 Instances
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "travelmemory-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = { Name = "travelmemory-ec2-role" }
}

# Attach AWS Systems Manager (SSM) policy to enable secure management/logging
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create IAM Instance Profile to attach to EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "travelmemory-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ------------------------------------------------------------------------------
# VPC and Subnets
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "travelmemory-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "travelmemory-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = { Name = "travelmemory-public-subnet" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "travelmemory-private-subnet" }
}

# ------------------------------------------------------------------------------
# Gateways & Route Tables
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "travelmemory-nat-gw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "travelmemory-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "travelmemory-private-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "travelmemory-web-sg"
  description = "Public Web Server SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from developer IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node API Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "travelmemory-db-sg"
  description = "Private MongoDB SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MongoDB from Web SG"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH Bastion from Web SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# EC2 Instances
# ------------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                  = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public.id
  key_name             = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  # Attached IAM Instance Profile
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = { Name = "TravelMemory-WebServer" }
}

resource "aws_instance" "db" {
  ami                  = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.private.id
  key_name             = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  # Attached IAM Instance Profile
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = { Name = "TravelMemory-DBServer" }
}
