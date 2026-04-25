terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Provider — pointed at LocalStack instead of real AWS
# In a real environment: remove the endpoint overrides below

provider "aws" {
  region                      = var.region
  access_key                  = "test"       # LocalStack accepts any value
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2      = "http://localhost:4566"
    s3       = "http://localhost:4566"
    iam      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}

# S3 Bucket — for storing app artifacts or state

resource "aws_s3_bucket" "lab_bucket" {
  bucket = "${var.environment}-${var.lab_tag}-bucket"

  tags = {
    Name        = "${var.environment}-lab-bucket"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "lab_bucket_versioning" {
  bucket = aws_s3_bucket.lab_bucket.id

  versioning_configuration {
    status = "Enabled"   # always enable versioning — good habit
  }
}

# ---------------------------------------------------------------
# Security Group — network access control
# TEACHING POINT: this is NOT hardening, it is access control
# ---------------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTP and SSH inbound traffic"

  # SSH — for Ansible to connect
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # in production restrict to your IP only
    # cidr_blocks = ["YOUR_IP/32"]
  }

  # HTTP — for the web app
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# EC2 Instance — the web server Ansible will configure
resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # In LocalStack this is simulated — in real AWS use an actual key pair
  # key_name = "lab-key"

  tags = {
    Name        = "${var.environment}-web-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Lab         = var.lab_tag
  }
}
