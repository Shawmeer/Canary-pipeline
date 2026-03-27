#VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "name" = "devops-vpc"
  }
}
#Subnet
resource "aws_subnet" "main" {
  cidr_block = var.subnet_cidr
  vpc_id     = aws_vpc.main.id
}
#Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "name" = "devops-igw"
  }
}

#route table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    "name" = "devops-rt"
  }
}
#route table association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}
#security group
resource "aws_security_group" "main" {
  name   = "devops-sg"
  vpc_id = aws_vpc.main.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    } 

      ingress{
        from_port = 3000
        to_port   = 3000
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      ingress{
        from_port = 3001
        to_port   = 3001
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      ingress{
        from_port = 3002
        to_port   = 3002
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      ingress{
        from_port = 3003
        to_port   = 3003
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      ingress{
        from_port = 8080
        to_port   = 8080
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      ingress{
        from_port = 443
        to_port   = 443
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }                                    

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        "name" = "devops-sg"
    }
}

#EC2 Instance
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.main.id

  tags = {
    Name = "devops-ec2-instance"
  }
}
# Single ECR Repository for all environments
resource "aws_ecr_repository" "app" {
  name = "devops-app-repo"
  image_tag_mutability = "MUTABLE"
  
  # Basic vulnerability scanning on push (built-in ECR scanning)
  # Note: For AWS Inspector enhanced scanning, enable it in AWS Console:
  # ECR > Repository > Image scanning > Enable enhanced scanning
  image_scanning_configuration {
    scan_on_push = true
  }
  
  force_delete = true
  tags = {
    "name" = "devops-app-repo"
  }
}

# Legacy repos - will be deleted when tf apply runs
resource "aws_ecr_repository" "prod" {
  name = "devops-app-prod"
  force_delete = true
}

resource "aws_ecr_repository" "dev" {
  name = "devops-app-dev"
  force_delete = true
}

resource "aws_ecr_repository" "staging" {
  name = "devops-app-staging"
  force_delete = true
}



