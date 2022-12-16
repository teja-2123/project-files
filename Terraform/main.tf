provider "aws" {
    region = "ap-south-1"
    access_key = "AKIATGY4OZAI3KVZ7L4R"
    secret_key = "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"
}

resource "aws_vpc" "myVPC" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "Project VPC"
 }
}

resource "aws_subnet" "public_subnet" {
 vpc_id     = aws_vpc.myVPC.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "ap-south-1a"
 tags = {
   Name = "Public Subnet"
 }
}

resource "aws_subnet" "private_subnet" {
 vpc_id     = aws_vpc.myVPC.id
 cidr_block = "10.0.2.0/24"
 availability_zone = "ap-south-1b"
 tags = {
   Name = "Private Subnet"
 }
}

resource "aws_internet_gateway" "gateway" {
 vpc_id = aws_vpc.myVPC.id
 
 tags = {
   Name = "Project VPC IG"
 }
}

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.myVPC.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gateway.id
 }
 
 tags = {
   Name = "first Route Table"
 }
}

resource "aws_route_table_association" "public_subnet_asso" {
 subnet_id      = aws_subnet.public_subnet.id
 route_table_id = aws_route_table.second_rt.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


resource "aws_instance" "ansible" {
  ami           = "ami-07ffb2f4d65357b42"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.allow_tls.id}"]
  key_name = "saiteja"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  provisioner "remote-exec" {
        inline = [
            "sudo apt update -y",
        "sudo apt install ansible-core -y"
    ]
    connection {
        type                = "ssh"
        user                = "ubuntu"
        private_key         = file("./saiteja.pem")
        host                = coalesce(self.public_ip, self.private_ip)
        timeout = "10m"
    }
  }
  tags = {
    Name = "Ansible"
  }
}

resource "aws_instance" "Jenkins" {
  ami           = "ami-07ffb2f4d65357b42"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.allow_tls.id}"]
  key_name = "saiteja"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "Jenkins"
  }
}
