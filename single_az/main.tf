resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    Name     = "tf-sandbox-${var.suffix}"
  }
}

resource "aws_security_group" "sg_ssh" {
  name        = "sg_ssh"
  description = "SSH Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH ingress"
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
  tags       = {
    Name     = "sg_ssh"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "public-snet-${count.index}"
  }
} 

resource "aws_internet_gateway" "igw" {
  vpc_id  = aws_vpc.main.id
  tags    = {
    Name  = "igw-${var.suffix}"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt-secondary-${var.suffix}"
  }
}

resource "aws_route_table_association" "public_subnet_second_rt" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.second_rt.id
}


# Put an instance in each subnet
resource "aws_instance" "public_ssh" {
  ami           = var.debian_ami
  associate_public_ip_address = "true"
  count = 1
  instance_type = var.base_instance_type
  key_name      = "wmcdonald@gmail.com aws ed25519-key-20211205"
  subnet_id     = aws_subnet.public_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.sg_ssh.id]
  tags = {
    Name = "ssh-${count.index}"
    MachineRole = "ssh"
  }
}