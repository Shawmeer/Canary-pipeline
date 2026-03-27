# Security Module - Variables
variable "environment" {
  type        = string
  default     = "devops"
  description = "Environment name for tagging"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to associate security group with"
}