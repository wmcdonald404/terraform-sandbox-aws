resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    Name     = "terraform-sandbox-${var.suffix}"
  }
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh_sg"
  description = "Allow SSH"
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
    Name     = "ssh_sg"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.all_azs, count.index)
  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
} 

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.all_azs, count.index)
  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id  = aws_vpc.main.id
  tags    = {
    Name  = "Project VPC IG"
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

# Put an instance in the "primary" subnet
resource "aws_instance" "public_bastions" {
  ami           = var.debian_ami
  associate_public_ip_address = "true"
  count         = 1
  instance_type = var.base_instance_type
  key_name      = "wmcdonald@gmail.com aws ed25519-key-20211205"
  subnet_id     = aws_subnet.public_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  tags = {
    InstanceName = "bastion-${count.index}"
    InstanceRole = "bastion"
  }
}

##  user volume
resource "aws_ebs_volume" "public_bastions_user_volumes" {
  count             = length(aws_instance.public_bastions)
  availability_zone = var.multi_azs[count.index]
  size              = 10
  type              = "gp3"
  tags = {
    InstanceName    = "bastion-${count.index}"
    VolumeName      = "user-volume-${count.index}"
    VolumePurpose   = "user-volume"
  }
}

resource "aws_volume_attachment" "public_bastions_user_volumes_attachments" {
  count        = length(aws_instance.public_bastions)
  instance_id  = aws_instance.public_bastions[count.index].id
  volume_id    = aws_ebs_volume.public_bastions_user_volumes[count.index].id
  device_name  = "/dev/xvdb"
  depends_on   = [aws_instance.public_bastions]
}

# # Put a database instance in a single subnet
# resource "aws_instance" "private_databases" {
#   ami            = var.debian_ami
#   count          = 1
#   instance_type  = var.base_instance_type
#   key_name       = "wmcdonald@gmail.com aws ed25519-key-20211205"
#   subnet_id      = aws_subnet.private_subnets[count.index].id
#   tags = {
#     InstanceName = "sql-database-${count.index}"
#     InstanceRole = "sql-database"
#   }
# }

# # Create and attach additional EBS volumes
# ##  backup volumes
# resource "aws_ebs_volume" "private_databases_backup_volumes" {
#   count             = length(aws_instance.private_databases)
#   availability_zone = var.multi_azs[count.index]
#   size              = 10
#   type              = "gp3"
#   tags = {
#     InstanceName    = "sql-database-${count.index}"
#     VolumeName      = "backup-volume-${count.index}"
#     VolumePurpose   = "backup-volume"
#   }
# }

# resource "aws_volume_attachment" "private_databases_backup_volumes_attachments" {
#   count        = length(aws_instance.private_databases)
#   instance_id  = aws_instance.private_databases[count.index].id
#   volume_id    = aws_ebs_volume.private_databases_backup_volumes[count.index].id
#   device_name  = "/dev/xvdb"
#   depends_on   = [aws_instance.private_databases]
# }

# ##  data volumes
# resource "aws_ebs_volume" "private_databases_data_volumes" {
#   count             = length(aws_instance.private_databases)
#   availability_zone = var.multi_azs[count.index]
#   size              = 2
#   type              = "gp3"
#   tags = {
#     InstanceName    = "sql-database-${count.index}"
#     VolumeName      = "data-volume-${count.index}"
#     VolumePurpose   = "data-volume"
#   }
# }

# resource "aws_volume_attachment" "private_databases_data_volumes_attachments" {
#   count        = length(aws_instance.private_databases)
#   instance_id  = aws_instance.private_databases[count.index].id
#   volume_id    = aws_ebs_volume.private_databases_data_volumes[count.index].id
#   device_name  = "/dev/xvdc"
#   depends_on   = [aws_instance.private_databases]
# }

# ##  log volumes
# resource "aws_ebs_volume" "private_databases_log_volumes" {
#   count             = length(aws_instance.private_databases)
#   availability_zone = var.multi_azs[count.index]
#   size              = 2
#   type              = "gp3"
#   tags = {
#     InstanceName    = "sql-database-${count.index}"
#     VolumeName      = "log-volume-${count.index}"
#     VolumePurpose   = "log-volume"
#   }
# }

# resource "aws_volume_attachment" "private_databases_log_volumes_attachments" {
#   count        = length(aws_instance.private_databases)
#   instance_id  = aws_instance.private_databases[count.index].id
#   volume_id    = aws_ebs_volume.private_databases_log_volumes[count.index].id
#   device_name  = "/dev/xvdd"
#   depends_on   = [aws_instance.private_databases]
# }

# ##  tempdb volumes
# resource "aws_ebs_volume" "private_databases_tempdb_volumes" {
#   count             = length(aws_instance.private_databases)
#   availability_zone = var.multi_azs[count.index]
#   size              = 2
#   type              = "gp3"
#   tags = {
#     InstanceName    = "sql-database-${count.index}"
#     VolumeName      = "tempdb-volume-${count.index}"
#     VolumePurpose   = "tempdb-volume"
#   }
# }

# resource "aws_volume_attachment" "private_databases_tempdb_volumes_attachments" {
#   count        = length(aws_instance.private_databases)
#   instance_id  = aws_instance.private_databases[count.index].id
#   volume_id    = aws_ebs_volume.private_databases_tempdb_volumes[count.index].id
#   device_name  = "/dev/xvde"
#   depends_on   = [aws_instance.private_databases]
# }