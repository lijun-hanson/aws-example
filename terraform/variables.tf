variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources into"
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "The aws_region must be a valid AWS region format (e.g., us-east-1, ap-southeast-2)."
  }
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type for the compute instance"
  default     = "t2.micro"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "subnet_cidr" {
  type        = string
  description = "The CIDR block for the public subnet"
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "The subnet_cidr must be a valid CIDR block (e.g., 10.0.1.0/24)."
  }
}

variable "project_name" {
  type        = string
  description = "The name of the project, used for resource naming and tagging"
}

variable "environment" {
  type        = string
  description = "The deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}
