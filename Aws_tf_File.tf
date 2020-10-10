provider "aws" {
  region  = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "sarvanvpc"
  }
}

resource "aws_internet_gateway" "mygw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "sarvangway"
  }
}
resource "aws_subnet" "publicsub" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Pubsub"
  }
}

resource "aws_subnet" "privsub" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Prisub"
  }

}
resource "aws_route_table" "pubrt" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mygw.id}"
  }

  tags = {
    Name = "publicrt"
  }
}

resource "aws_eip" "elasticip" {
  vpc      = true
  tags = {
    Name = "elasticip"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.elasticip.id}"
  subnet_id     = "${aws_subnet.publicsub.id}"

  tags = {
    Name = "natgw"
  }
}
resource "aws_route_table" "prirt" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.natgw.id}"
  }

  tags = {
    Name = "privatert"
  }
}

resource "aws_route_table_association" "pubassociate" {
  subnet_id      = "${aws_subnet.publicsub.id}"
  route_table_id = "${aws_route_table.pubrt.id}"
}

resource "aws_route_table_association" "priassociate" {
  subnet_id      = "${aws_subnet.privsub.id}"
  route_table_id = "${aws_route_table.prirt.id}"
}

resource "aws_security_group" "pubsec" {
  name        = "pubsec"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
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

  tags = {
    Name = "pubsec"
  }

}
  resource "aws_instance" "pubec2" {
  ami                         = "ami-0ebc1ac48dfd14136"
  instance_type               = "t2.micro"
  key_name                    = "Latest Key"
  vpc_security_group_ids      = ["${aws_security_group.pubsec.id}"]
  subnet_id                   = "${aws_subnet.publicsub.id}"
  associate_public_ip_address = true
  user_data = <<-EOF
              #! /bin/bash
              yum install httpd -y
              service httpd start
              echo "welcome to terraform" > /var/www/html/index.html
              EOF

  tags = {
    Name = "pubec2"
  }

}
resource "aws_instance" "privec2" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
  key_name      = "Latest Key"
  vpc_security_group_ids = ["${aws_security_group.pubsec.id}"]
  subnet_id  = "${aws_subnet.privsub.id}"
  user_data = <<-EOF
              #! /bin/bash
              vi index.html
              echo "welcome to terraform" > index.html
              EOF

  tags = {
    Name = "priec2"
  }

}
