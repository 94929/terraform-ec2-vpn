resource "aws_vpc" "vpn_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.app_name}-vpn-vpc"
  }
}

resource "aws_internet_gateway" "vpn_gw" {
  vpc_id = aws_vpc.vpn_vpc.id
}

resource "aws_route_table" "vpn_rt" {
  vpc_id = aws_vpc.vpn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_gw.id
  }
}

resource "aws_subnet" "vpn_public_subnet" {
  vpc_id            = aws_vpc.vpn_vpc.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = "${var.region}a"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-vpn-public-subnet"
  }
}

resource "aws_route_table_association" "vpn_public_subnet_association" {
  subnet_id      = aws_subnet.vpn_public_subnet.id
  route_table_id = aws_route_table.vpn_rt.id
}

resource "aws_security_group" "vpn_sg" {
  name   = "${var.app_name}-vpn-sg"
  vpc_id = aws_vpc.vpn_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-security-group"
  }
}

#
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "vpn-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem

  provisioner "local-exec" {
    command = "chmod 400 ${aws_key_pair.key_pair.key_name}.pem"
  }
}

resource "aws_instance" "vpn_ec2" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.vpn_public_subnet.id
  vpc_security_group_ids = [aws_security_group.vpn_sg.id]

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("${aws_key_pair.key_pair.key_name}.pem")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "/tmp/bootstrap.sh"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("${aws_key_pair.key_pair.key_name}.pem")
    }
  }

  tags = {
    Name = "${var.app_name}-vpn-ec2"
  }
}

data "aws_route53_zone" "selected_zone" {
  name = var.ec2_hosted_zone_name
}

resource "aws_route53_record" "vpn_record" {
  zone_id = data.aws_route53_zone.selected_zone.zone_id
  name    = var.ec2_domain
  type    = "A"
  ttl     = "300"
  records = [aws_instance.vpn_ec2.public_ip]
}

