# Networking Module - Variables
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Subnet CIDR block"
}

variable "environment" {
  type        = string
  default     = "devops"
  description = "Environment name for tagging"
}

variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region"
}

variable "security_group_id" {
  type        = string
  default     = ""
  description = "Security group ID for output reference"
}