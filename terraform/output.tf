# Root Module Outputs
# Re-exports outputs from the core infrastructure module

output "vpc_id" {
  value = module.core.vpc_id
}

output "subnet_id" {
  value = module.core.subnet_id
}

output "ec2_public_ip" {
  value = module.core.ec2_public_ip
}

output "ecr_repository_url" {
  value = module.core.ecr_repository_url
}
