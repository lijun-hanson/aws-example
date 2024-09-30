terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65"
    }
  }

  required_version = ">= 1.6.0"
}

provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      CostCode = "aws-example"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2-ssm-role" {
  name               = "ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2-ssm-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2-ssm-iam-profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-ssm-role.name
}

resource "aws_security_group" "allow_ssh_web" {
  vpc_id      = aws_vpc.main.id
  description = "Allows access to SSH and HTTPs ports"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "nginx_key" {
  key_name   = "nginx"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7JaVVqEyrqIlV3K5/dhXYqiGvkBHHCEmqbMYdAU0SHGB7XYQNg4P5DbSrFBtT4hHsnNvaKKClzdp0ZE+VaH3TJprR3cm1UEoKwyDfAIxHalXBsLJ35qyUjpy8vk7FGvbe5OowChoyowEypw1+zNhGZV9IN/r3zd3uc3WIsIyP7W8IGjYNZjGxvCNNXIQ9zLDgo65N5Ik01n8UFTtkh+kxG+z0hT3buCbdqjYotqQCu3Gk9UxR/emDV1Fy7k5IsKW1TGbmhN7vZu9rqAlpn9Ltsf3aRgMOEDm7nvR7umu19rKx8PSQjumeU86N582wFTjieAeS7aqDKCIZmu2yLAf5jtFCIJM8X8XtB+LYrS8Y4GGc0tbnF0EvjEY6RSNKW5gZ86xwhsMQZFNZZJch61kBb4rsBXJMX/zDjEzOobKrgcPd7M82Blk0zoxGZkbsnHZA4a82e8qvKv5RRK/DMkHj2QnDWB4qVv+BqU8wWzPY7cqqKItGRxFjtjMNx7q3+00= MAC@MacBook-Pro.local"
}

resource "aws_instance" "nginx" {
  ami                         = "ami-0e8fd5cc56e4d158c"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2-ssm-iam-profile.name
  key_name                    = aws_key_pair.nginx_key.key_name

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 8
  }
  tags = {
    Name = "nginx"
  }
}
