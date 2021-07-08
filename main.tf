terraform {
  required_version = "~> 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*20*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "user_data" {
  template = file("scripts/add-ssh-web-app.yaml")
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
#  subnet_id                   = aws_subnet.subnet_public.id
#  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered

  tags = {
    "cost_center" = var.cost_center
  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment1" {
  security_group_id    = "sg-002fefea4006ef36e"
  network_interface_id = "${aws_instance.web.primary_network_interface_id}"
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
