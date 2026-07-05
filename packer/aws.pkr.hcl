packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
    ansible = {
      source = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "source_ami" {
  type    = string
  default = "ami-06067086cf86c58e6"
}

variable "ami_name_prefix" {
  type    = string
  default = "packer-nginx-ami"
}

source "amazon-ebs" "custom-ami" {
  ami_name              = "${var.ami_name_prefix}-${formatdate("YYYYMMDDHHmm", timestamp())}"
  ami_description       = "Nginx web server with HTTPS support on Amazon Linux 2023"
  instance_type         = var.instance_type
  region                = var.region
  source_ami            = var.source_ami
  ssh_username          = "ec2-user"
  force_deregister      = true
  force_delete_snapshot = true
  tags = {
    Name = var.ami_name_prefix
  }
}

build {
  sources = ["source.amazon-ebs.custom-ami"]

  provisioner "ansible" {
    playbook_file = "../ansible/nginx.yml"
    user          = "ec2-user"
    extra_arguments = [
      "--scp-extra-args", "'-O'",
      "-e", "ansible_scp_extra_args=-O"
    ]
  }
}
