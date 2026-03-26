output "vpc_id" {
  value = aws_vpc.main.id
}
output "subnet_id" {
  value = aws_subnet.main.id
}
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
