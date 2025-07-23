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

variable "agent_config_name" {
  default = "ec2_metrics"
  type = string
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = var.agent_config_name
  type  = "String"
  value = jsonencode({
    "agent" : {
      "metrics_collection_interval" : 60,
      "run_as_user" : "cwagent"
    },
    "metrics" : {
      "metrics_collected" : {
        "cpu" : {
          "measurement" : [
            "cpu_usage_idle",
            "cpu_usage_iowait",
            "cpu_usage_user",
            "cpu_usage_system"
          ],
          "metrics_collection_interval" : 60,
          "totalcpu" : false
        },
        "disk" : {
          "measurement" : [
            "used_percent"
          ],
          "metrics_collection_interval" : 60,
          "resources" : [
            "*"
          ]
        },
        "mem" : {
          "measurement" : [
            "mem_used_percent"
          ],
          "metrics_collection_interval" : 60
        }
      }
    }
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_cloudwatch_agent_role"

    assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_cloudwatch_agent_profile"
  role = aws_iam_role.ec2_role.name
}

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

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-cloudwatch-agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${var.agent_config_name} -s
              EOF
}
