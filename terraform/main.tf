# =============================================================================
# main.tf
# Research Paper: A Comparative Study of Infrastructure Automation Tools
# Tool: Terraform 1.9.x
# Task: Provision EC2 instance + Configure Nginx on AWS
# Authors: Risham Goyal, Vaibhav Khanna, Sujal Jain — Chitkara University
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend (S3 + DynamoDB locking — as used in experiment)
  # Uncomment and configure before use:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cloud-automation-study/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# ── Provider ──────────────────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloud-automation-study"
      Tool        = "terraform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Paper       = "Comparative Study of Infrastructure Automation Tools"
    }
  }
}

# ── Data Sources ──────────────────────────────────────────────────────────────
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "webserver" {
  name        = "${var.project_name}-webserver-sg"
  description = "Security group for research study webserver nodes"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from control node only
  ingress {
    description = "SSH from control node"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.control_node_cidr]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-webserver-sg"
    Role = "webserver"
  }
}

# ── EC2 Instances ─────────────────────────────────────────────────────────────
resource "aws_instance" "webserver" {
  count = var.node_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.webserver.id]
  subnet_id              = data.aws_subnets.default.ids[count.index % length(data.aws_subnets.default.ids)]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-node-${count.index + 1}"
    Role        = "webserver"
    NodeIndex   = tostring(count.index + 1)
  }
}

# ── Nginx Installation via remote-exec ───────────────────────────────────────
# Note: In the research paper, this provisioner handles Steps 2, 3, and 4
# of the standard automation task after EC2 creation (Step 1).
resource "null_resource" "configure_webserver" {
  count = var.node_count

  depends_on = [aws_instance.webserver]

  triggers = {
    instance_id = aws_instance.webserver[count.index].id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.webserver[count.index].private_ip
    timeout     = "5m"
  }

  # Step 2: Install Nginx
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -qq",
      "sudo apt-get install -y nginx=1.24.*",
      "echo 'Nginx installed successfully'"
    ]
  }

  # Step 3: Deploy configuration
  provisioner "file" {
    content = templatefile("${path.module}/templates/nginx.conf.tpl", {
      node_index  = count.index + 1
      project     = var.project_name
      environment = var.environment
      hostname    = aws_instance.webserver[count.index].private_dns
    })
    destination = "/tmp/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo nginx -t",
      "sudo systemctl restart nginx",
      "sudo systemctl enable nginx"
    ]
  }

  # Step 4: Verify
  provisioner "remote-exec" {
    inline = [
      "sleep 2",
      "curl -sf http://localhost/health || (echo 'Health check failed' && exit 1)",
      "echo 'Node ${count.index + 1} deployment verified successfully'"
    ]
  }
}
