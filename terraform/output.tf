output "vpc_id" {
  value = aws_vpc.main.id
}
output "subnet_id" {
  value = aws_subnet.main.id
}
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "ecr_repository_prod_url" {
  value = aws_ecr_repository.prod.repository_url
}
output "ecr_repository_dev_url" {
  value = aws_ecr_repository.dev.repository_url
}
output "ecr_repository_staging_url" {
  value = aws_ecr_repository.staging.repository_url
}