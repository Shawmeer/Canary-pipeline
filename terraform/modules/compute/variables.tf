# Compute Module - Variables
variable "environment" {
  type        = string
  default     = "devops"
  description = "Environment name for tagging"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for EC2 instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for EC2 instance"
}

variable "key_name" {
  type        = string
  default     = "devops-key"
  description = "Key pair name for SSH access"
}