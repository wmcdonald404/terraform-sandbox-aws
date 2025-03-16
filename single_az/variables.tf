variable "all_azs" {
  type        = list(string)
  description = "All AWS Availability Zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "amis" {
  type        = map
  description = "AMI list"
  default     = {
    "amazon2023"  = "ami-08f9a9c699d2ab3f9"
    "debian12"    = "ami-0eb11ab33f229b26c"
    "rhel9"       = "ami-0343a21cd4b9d8ee8"
    "ubuntu24"    = "ami-03fd334507439f4d1"
    }
}

variable "ami" {
  type        = string
  description = "AMI"
  default     = "ubuntu24"
}

# See the Map entry here: https://upcloud.com/resources/tutorials/terraform-variables#Map
# for a nice map option to set small/medium/large options.
variable "base_instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "debian_user_data" {
  type = string
  description = "UserData to install SSM agent when distro is Debian"
  default = <<-EOF
  #!/bin/bash
  if [ -f "/etc/debian_version" ]
  then
      mkdir /tmp/ssm
      wget -O /tmp/ssm/amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb 
      sudo dpkg -i /tmp/ssm/amazon-ssm-agent.deb
  fi
  EOF
}

variable "keypair" {
  type        = string
  description = "Keypair name"
  default     = ""
}

variable "multi_azs" {
  type        = list(string)
  description = "Multiple AWS Availability Zones"
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "projectid" {
  type        = string
  description = "Project identifier/name"
  default     = "tf-sandbox-aws"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "single_az" {
  type        = string
  description = "Primary AWS Availability Zone"
  default     = "eu-west-1a"
}
variable "suffix" {
  type        = string
  description = "Suffix string to append to resources"
  default     = "single-az"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for the VPC"
  default     = "10.0.0.0/16"
}