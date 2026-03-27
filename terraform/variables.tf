variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "region name"
}
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "instance type"
}
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

variable "key_name" {
  type        = string
  default     = "devops-key"
  description = "Name of the key pair"
}

variable "environment" {
  type        = string
  default     = "devops"
  description = "Environment name (dev, staging, prod)"
}

variable "app_name" {
  type        = string
  default     = "devops-app"
  description = "Application name for resources"
}