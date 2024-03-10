terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.39"
    }
  }

  required_version = ">= 1.7.4"
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnet" "ap-northeast-1a" {
  id = var.subnet_ids["ap-northeast-1a"]
}

data "aws_subnet" "ap-northeast-1c" {
  id = var.subnet_ids["ap-northeast-1c"]
}

data "aws_subnet" "ap-northeast-1d" {
  id = var.subnet_ids["ap-northeast-1d"]
}

data "aws_security_group" "default" {
  id = var.default_security_group_id
}

# resource "aws_instance" "nginx" {
#   launch_template {
#     id      = aws_launch_template.nginx.id
#     version = "$Latest"
#   }
# }

resource "aws_security_group" "allow_instance_connect" {
  name   = "allow_instance_connect"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_instance_connect.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "3.112.23.0/29"
}

resource "aws_security_group" "allow_http" {
  name   = "allow_http"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_http.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_launch_template" "nginx" {
  name                   = "nginx"
  image_id               = "ami-0d889f77081190db1"
  instance_type          = "t3.nano"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_instance_connect.id, data.aws_security_group.default.id]
  # network_interfaces {
  #   associate_public_ip_address = false
  #   security_groups             = [aws_security_group.allow_instance_connect.id, data.aws_security_group.default.id, aws_security_group.allow_http.id]
  # }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }
  user_data = filebase64("${path.module}/userdata.sh")
}

resource "aws_autoscaling_group" "nginx" {
  desired_capacity = 1
  max_size         = 2
  min_size         = 1
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
  vpc_zone_identifier = [data.aws_subnet.ap-northeast-1a.id, data.aws_subnet.ap-northeast-1c.id, data.aws_subnet.ap-northeast-1d.id]
  target_group_arns   = [aws_lb_target_group.nginx.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  instance_maintenance_policy {
    min_healthy_percentage = 100
    max_healthy_percentage = 110
  }
}

resource "aws_autoscaling_policy" "nginx" {
  name                   = "nginx"
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
