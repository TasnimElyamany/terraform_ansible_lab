# ---------------------------------------------------------------
# Outputs — exposed values used by Ansible and CI/CD pipelines
# Run: terraform output web_server_ip
# ---------------------------------------------------------------

output "web_server_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web_server.id
}

output "web_server_ip" {
  description = "Public IP — Ansible will use this to connect"
  value       = aws_instance.web_server.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created"
  value       = aws_s3_bucket.lab_bucket.bucket
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.web_sg.id
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}
