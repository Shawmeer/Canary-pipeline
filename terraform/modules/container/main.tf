# Container Module - ECR Repositories

# Main application repository
resource "aws_ecr_repository" "app" {
  name = "${var.app_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Name = "${var.app_name}-repo"
  }
}

# Legacy repositories (for backward compatibility during migration)
resource "aws_ecr_repository" "prod" {
  name = "${var.app_name}-prod"
  force_delete = true
}

resource "aws_ecr_repository" "dev" {
  name = "${var.app_name}-dev"
  force_delete = true
}

resource "aws_ecr_repository" "staging" {
  name = "${var.app_name}-staging"
  force_delete = true
}

# Module Outputs
output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.app.arn
}