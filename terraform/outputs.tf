# =============================================================================
# outputs.tf — Output values after apply
# =============================================================================

output "instance_ids" {
  description = "IDs of all provisioned EC2 instances"
  value       = aws_instance.webserver[*].id
}

output "private_ips" {
  description = "Private IP addresses of all webserver nodes"
  value       = aws_instance.webserver[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses of all webserver nodes"
  value       = aws_instance.webserver[*].public_ip
}

output "security_group_id" {
  description = "ID of the webserver security group"
  value       = aws_security_group.webserver.id
}

output "node_count" {
  description = "Number of nodes provisioned"
  value       = var.node_count
}

output "ami_id" {
  description = "AMI used for all instances"
  value       = data.aws_ami.ubuntu.id
}

output "health_check_urls" {
  description = "Health check URLs for all nodes"
  value       = [for ip in aws_instance.webserver[*].private_ip : "http://${ip}/health"]
}
