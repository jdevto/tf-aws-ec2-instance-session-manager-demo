# Generate a random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name = "ec2-instance-session-manager-demo-${random_string.suffix.result}"
}

# Get the current AWS region
data "aws_region" "current" {}

# Create VPC
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.name
  }
}

# Create Private Subnet (For SSM Manage Nodes)
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "${local.name}-private"
  }
}

# Create Public Subnet (For NAT Gateway)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public"
  }
}

# Create Internet Gateway (Required for NAT Gateway)
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = local.name
  }
}

# Create NAT Gateway in Public Subnet
resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${local.name}-nat"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Route Table for Private Subnet (Uses NAT Gateway for outbound internet)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.example.id
  }

  tags = {
    Name = "${local.name}-private-rt"
  }
}

# Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create Security Group for SSM
resource "aws_security_group" "ssm" {
  name        = "${local.name}-sg"
  description = "Allow only SSM access"
  vpc_id      = aws_vpc.example.id

  # Allow HTTPS for AWS SSM (Session Manager)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS for AWS Systems Manager"
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg"
  }
}

# Create IAM Role for SSM Access
resource "aws_iam_role" "ssm_instance_role" {
  name = "${local.name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach Policies to IAM Role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_instance_role.name
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${local.name}-ssm-profile"
  role = aws_iam_role.ssm_instance_role.name
}

# Fetch Latest Amazon Linux 2 AMI
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Fetch Latest Amazon Linux 2023 AMI
data "aws_ami" "amzn2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

# Create EC2 Instance in Private Subnet for SSM
resource "aws_instance" "jumphost1" {
  ami                  = data.aws_ami.amzn2.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.private.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [
    aws_security_group.ssm.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Set hostname
    hostnamectl set-hostname jumphost1

    echo "Session Manager Setup Complete"
  EOF

  tags = {
    Name = "${local.name}-jumphost1"
  }
}

# Create EC2 Instance with Amazon Linux 2023
resource "aws_instance" "jumphost2" {
  ami                  = data.aws_ami.amzn2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.private.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [
    aws_security_group.ssm.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Set hostname
    hostnamectl set-hostname jumphost2

    # Install & Start AWS SSM Agent (required for Session Manager)
    # Amazon Linux 2023 does NOT come with the SSM Agent pre-installed
    dnf install -y amazon-ssm-agent
    systemctl enable --now amazon-ssm-agent

    echo "AWS SSM Session Manager setup complete."
  EOF

  tags = {
    Name = "${local.name}-jumphost2"
  }
}
