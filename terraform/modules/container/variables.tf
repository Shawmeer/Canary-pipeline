# Container Registry Module - Variables
variable "environment" {
  type        = string
  default     = "devops"
  description = "Environment name for tagging"
}

variable "app_name" {
  type        = string
  default     = "devops-app"
  description = "Application name for repository naming"
}