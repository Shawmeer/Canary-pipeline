# Compute Module - EC2 Instance

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id

  tags = {
    Name = "${var.environment}-ec2-instance"
  }
}

# Module Outputs
output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}