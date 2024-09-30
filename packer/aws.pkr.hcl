packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.1.1"
    }
  }
}
source "amazon-ebs" "custom-ami" {
  ami_name      = "packer-nginx-ami"
  instance_type = "t2.micro"
  region        = "ap-southeast-2"
  source_ami    = "ami-0e8fd5cc56e4d158c"
  ssh_username  = "ec2-user"
  tags = {
    Name = "packer-nginx-ami"
  }
}
build {
  sources = ["source.amazon-ebs.custom-ami"]

  provisioner "ansible" {
    playbook_file = "../ansible/nginx.yml"
    user          = "ec2-user"
  }
}
