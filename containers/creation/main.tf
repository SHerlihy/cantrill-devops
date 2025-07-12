terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "cantrill-general-admin"
  region  = "us-east-1"
}

# Create a new key pair for SSH access
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tf-key-pair" # You can change this name
  public_key = tls_private_key.rsa.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "tf_private_key" {
  content         = tls_private_key.rsa.private_key_pem
  filename        = "tf-key.pem"
  file_permission = "0400"
}

# Create a security group to allow SSH traffic
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: This allows SSH from any IP. For production, you should restrict this to your own IP address.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http" {
  name = "allow_http"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: This allows SSH from any IP. For production, you should restrict this to your own IP address.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch the EC2 instance
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro" # Free-tier eligible
  key_name      = aws_key_pair.tf_key.key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id
  ]

  tags = {
    Name = "MyWebServer"
  }

  provisioner "file" {
    source      = "container.zip"
    destination = "/tmp/container.zip"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.rsa.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "upload_image.sh"
    destination = "/tmp/upload_image.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.rsa.private_key_pem
      host        = self.public_ip
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user

              unzip /tmp/container.zip -d /home/ec2-user/

              su - ec2-user
              cd /home/ec2-user/container
              docker build -t containerofcats .

              # docker run -t -i -p 80:80 containerofcats
              EOF
}

# Output the public IP address of the instance
output "public_dns" {
  value = aws_instance.web_server.public_dns
}
