# Core Infrastructure Module
# This module composes all infrastructure components

module "networking" {
  source = "../networking"

  # Variables
  vpc_cidr     = var.vpc_cidr
  subnet_cidr  = var.subnet_cidr
  environment  = var.environment
  aws_region   = var.aws_region
}

module "security" {
  source = "../security"

  # Variables
  vpc_id      = module.networking.vpc_id
  environment = var.environment
}

module "compute" {
  source = "../compute"

  # Variables
  ami_id             = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  subnet_id         = module.networking.subnet_id
  security_group_ids = [module.security.security_group_id]
  key_name          = var.key_name
  environment       = var.environment
}

module "container" {
  source = "../container"

  # Variables
  environment = var.environment
  app_name    = var.app_name
}

# Data Sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Module Outputs - Re-export for backward compatibility
output "vpc_id" {
  value = module.networking.vpc_id
}

output "subnet_id" {
  value = module.networking.subnet_id
}

output "ec2_public_ip" {
  value = module.compute.public_ip
}

output "ecr_repository_url" {
  value = module.container.repository_url
}