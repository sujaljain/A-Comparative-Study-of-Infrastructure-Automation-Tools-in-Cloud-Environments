# =============================================================================
# variables.tf — Input variable definitions
# =============================================================================

variable "aws_region" {
  description = "AWS region for deployment (paper used ap-south-1 Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource tagging and naming"
  type        = string
  default     = "cloud-automation-study"
}

variable "environment" {
  description = "Environment tag (research / production)"
  type        = string
  default     = "research"
}

variable "instance_type" {
  description = "EC2 instance type for managed nodes (paper used t3.medium)"
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Number of managed nodes to provision (paper tested 5, 10, 25, 50)"
  type        = number
  default     = 5

  validation {
    condition     = contains([5, 10, 25, 50], var.node_count)
    error_message = "node_count must be one of: 5, 10, 25, 50 (as used in the research experiment)."
  }
}

variable "key_pair_name" {
  description = "Name of the AWS EC2 key pair for SSH access"
  type        = string
}

variable "private_key_path" {
  description = "Local path to the private key file (.pem)"
  type        = string
  default     = "~/.ssh/chitkara-research-key.pem"
}

variable "control_node_cidr" {
  description = "CIDR block of the control node for SSH access restriction"
  type        = string
  default     = "10.0.0.0/8"
}
