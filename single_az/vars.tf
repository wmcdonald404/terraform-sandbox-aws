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

# https://wiki.debian.org/Cloud/AmazonEC2Image/Bookworm
variable "debian_ami" {
  type        = string
  description = "Debian 12 (HVM), SSD Volume Type"
  default     = "ami-0eb11ab33f229b26c"
}

# https://aws.amazon.com/marketplace/pp/prodview-s4zvkzmlirbga?sr=0-7&ref_=beagle&applicationId=AWSMPContessa
variable "ubuntu_ami" {
  type        = string
  description = "Ubuntu Server 24.04 LTS (HVM), SSD Volume Type"
  default     = "ami-0776c814353b4814d"
}

variable "base_instance_type" {
  type        = string
  description = "EC2 instance"
  default     = "t2.micro"
}
