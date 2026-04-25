variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID — using a generic placeholder for LocalStack"
  type        = string
  default     = "ami-00000000"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lab_tag" {
  description = "Tag to identify all lab resources"
  type        = string
  default     = "terraform-ansible-lab"
}
