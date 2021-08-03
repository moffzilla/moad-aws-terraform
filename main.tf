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

resource "aws_security_group" "sg_22_80" {
  name   = "sg_22"
  vpc_id =  "vpc-e867aa92"

  # SSH access from the VPC
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
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_subnet_ids" "example" {
  vpc_id = "vpc-e867aa92"
}

data "aws_subnet" "example" {
  for_each = data.aws_subnet_ids.example.ids
  id       = each.value
}

data "template_file" "user_data" {
  template = file("scripts/add-ssh-web-app.yaml")
}

resource "aws_instance" "web" {
  for_each      = data.aws_subnet_ids.example.ids
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  #availability_zone = var.region
  subnet_id                   = each.value
  vpc_security_group_ids      = [data.aws_security_group.selected.vpc_id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered
#  security_groups = [
#      "sg-24b4946e"
#  ]  

  tags = {
    "cost_center" = var.cost_center
  }
}

#output "public_ip" {
#  value = aws_instance.web["${each.key}"].public_ip
#}
