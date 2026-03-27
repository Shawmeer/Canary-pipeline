# Root Terraform Configuration
# Main entry point that uses the core infrastructure module

module "core" {
  source = "./modules/core"

  # Core infrastructure variables
  environment  = var.environment
  app_name     = var.app_name
  vpc_cidr     = var.vpc_cidr
  subnet_cidr  = var.subnet_cidr
  instance_type = var.instance_type
  key_name     = var.key_name
  aws_region   = var.aws_region
}
