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
  name        = "allow_ssh_web"
  vpc_id      = aws_vpc.main.id
  description = "Allows access to SSH and HTTP/s ports"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

resource "aws_instance" "nginx" {
  ami                         = "ami-0e8fd5cc56e4d158c"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2-ssm-iam-profile.name
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 8
  }
  tags = {
    Name = "nginx"
  }
}

resource "aws_ec2_instance_state" "nginx-state" {
  instance_id = aws_instance.nginx.id
  state       = "stopped"
}
