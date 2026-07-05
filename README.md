# aws-example

## Prerequisites

AWS CLI configured with valid credentials, Terraform >= 1.6, Packer >= 1.10, Ansible >= 2.15 installed locally, and the `community.crypto` Ansible collection installed:

```bash
ansible-galaxy collection install community.crypto
```

## Step 1 — Build the AMI with Packer

```bash
cd packer
packer init .
packer build .
```

This runs Ansible against a temporary EC2 instance to install/configure nginx + TLS, then snapshots it as an AMI. The timestamped name means each build produces a uniquely identified image.

## Step 2 — Deploy infrastructure with Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if you want to override any defaults

terraform init
terraform plan    # review what will be created
terraform apply   # confirm with "yes"
```

Terraform will look up the latest `packer-nginx-ami*` AMI you just built and launch an EC2 instance from it.