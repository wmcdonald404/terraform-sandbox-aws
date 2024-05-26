resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform-sandbox"
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.all_azs, count.index)
  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
} 

resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.all_azs, count.index)
  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Project VPC IG"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "second_rt"
  }
}

# Put an instance in each subnet
resource "aws_instance" "instances" {
  count         = length(var.multi_azs)
  ami           = var.debian_ami
  instance_type = var.base_instance_type
  subnet_id     = aws_subnet.private_subnets[count.index].id
  tags = {
    Name = "instance-${count.index}"
  }
}

# Create additional EBS volumes
resource "aws_ebs_volume" "data_volumes" {
  count             = 2
  availability_zone = element(var.multi_azs, count.index % length(var.multi_azs))
  size              = 5
  type              = "gp3"
  tags = {
    Name = "data_volume_${count.index}"
  }
}

# Attach additional EBS volumes to instances
resource "aws_volume_attachment" "ebs_attachments" {
  count        = length(var.multi_azs)
  instance_id  = aws_instance.instances[count.index].id
  volume_id    = aws_ebs_volume.data_volumes[count.index].id
  device_name  = "/dev/xvdb"
  depends_on = [aws_instance.instances]
}