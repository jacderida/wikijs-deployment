terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_vpc" "wikijs" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "wikijs"
  }
}

resource "aws_subnet" "wikijs" {
  vpc_id     = aws_vpc.wikijs.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "wikijs"
  }
}

resource "aws_key_pair" "wikijs" {
  key_name   = "wikijs"
  public_key = file("~/.ssh/wikijs.pub")
}

resource "aws_security_group" "wikijs" {
  name        = "wikijs"
  description = "All necessary inbound and outbound traffic"
  vpc_id      = aws_vpc.wikijs.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "wikijs" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.wikijs.id
  key_name      = aws_key_pair.wikijs.key_name
  vpc_security_group_ids = [aws_security_group.wikijs.id]
  iam_instance_profile = aws_iam_instance_profile.upload_backups.name
  tags = {
    Name = "wikijs"
  }
}

resource "aws_ebs_volume" "wikijs" {
  availability_zone = aws_instance.wikijs.availability_zone
  size              = 50
  tags = {
    Name = "wikijs"
  }
}

resource "aws_volume_attachment" "wikijs" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.wikijs.id
  instance_id = aws_instance.wikijs.id
}

resource "aws_internet_gateway" "wikijs" {
  vpc_id = aws_vpc.wikijs.id
}

resource "aws_route_table" "wikijs" {
  vpc_id = aws_vpc.wikijs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wikijs.id
  }
}

resource "aws_route_table_association" "wikijs" {
  subnet_id      = aws_subnet.wikijs.id
  route_table_id = aws_route_table.wikijs.id
}

resource "aws_eip" "wikijs" {
  instance = aws_instance.wikijs.id
}
