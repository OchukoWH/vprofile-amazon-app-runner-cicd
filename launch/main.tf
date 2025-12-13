terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# IAM Role for EC2 instance to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "vprofile-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "vprofile-ec2-ecr-role"
    Environment = "state"
    Project     = "vprofile"
  }
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "vprofile-ec2-ecr-policy"
  role = aws_iam_role.ec2_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "vprofile-ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name

  tags = {
    Name        = "vprofile-ec2-ecr-profile"
    Environment = "state"
    Project     = "vprofile"
  }
}

# Security Group for EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "vprofile-ec2-sg"
  description = "Security group for VProfile EC2 instance running Docker Compose"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTP traffic on port 80
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (optional, but useful for troubleshooting)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "vprofile-ec2-sg"
    Environment = "state"
    Project     = "vprofile"
  }
}

# EC2 Instance
resource "aws_instance" "vprofile_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = "vprofile-key"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_profile.name
  user_data              = base64encode(templatefile("${path.module}/user-data.sh", {
    aws_region     = var.region
    aws_account_id = data.aws_caller_identity.current.account_id
    ecr_repo_db    = var.ecr_repo_db
    ecr_repo_app   = var.ecr_repo_app
    ecr_repo_web   = var.ecr_repo_web
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "vprofile-app"
    Environment = "state"
    Project     = "vprofile"
  }
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

