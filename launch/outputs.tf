output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.vprofile_app.id
}

output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.vprofile_app.public_ip
}

output "ec2_instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.vprofile_app.public_dns
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.vprofile_app.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2_sg.id
}

output "iam_role_arn" {
  description = "IAM role ARN for EC2 instance"
  value       = aws_iam_role.ec2_ecr_role.arn
}

