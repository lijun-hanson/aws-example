output "instance_public_ip" {
  description = "Public IP address of the Nginx EC2 instance"
  value       = aws_instance.nginx.public_ip
}

output "instance_id" {
  description = "Instance ID of the Nginx EC2 instance"
  value       = aws_instance.nginx.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "Security group ID for the Nginx instance"
  value       = aws_security_group.web.id
}
