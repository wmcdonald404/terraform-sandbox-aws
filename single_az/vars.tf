variable "suffix" {
  type        = string
  description = "Suffix string to append to resources"
  default     = "single"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "azs" {
  type        = list(string)
  description = "All AWS Availability Zones"
  default     = ["eu-west-1a"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24"]
}

variable "debian_ami" {
  type        = string
  description = "Debian 12 (HVM), SSD Volume Type"
  default     = "ami-0eb11ab33f229b26c"
}

variable "base_instance_type" {
  type        = string
  description = "EC2 instance"
  default     = "t2.micro"
}
