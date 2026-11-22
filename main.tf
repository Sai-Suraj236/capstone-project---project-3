provider "aws" {
  region = "eu-north-1"
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_key_pair" "project3_key" {
  key_name   = "project3-key"
  public_key = file(pathexpand("~/.ssh/project3-key.pub"))
}

resource "aws_security_group" "project3_sg" {
  name        = "project3-security-group"
  description = "Allow SSH access to EC2"
  vpc_id = "vpc-08712dccc114af956"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["20.197.25.80/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project3-security-group"
  }
}

resource "aws_instance" "project3_ec2" {
    user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    cat > /usr/local/bin/cpu-load.sh <<'SCRIPT'
    #!/bin/bash
    while true; do :; done &
    while true; do :; done &
    wait
    SCRIPT

    chmod +x /usr/local/bin/cpu-load.sh

    nohup /usr/local/bin/cpu-load.sh > /var/log/cpu-load.log 2>&1 &
  EOF
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id = "subnet-03494cac4f699b57e"

  key_name = aws_key_pair.project3_key.key_name

  vpc_security_group_ids = [
    aws_security_group.project3_sg.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "Project3-CloudWatch-EC2"
  }
}

output "ec2_public_ip" {
  value = aws_instance.project3_ec2.public_ip
}
output "ec2_instance_id" {
  value = aws_instance.project3_ec2.id
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "Project3-High-CPU-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  alarm_description = "Alarm when EC2 CPU utilization exceeds 70 percent"

  dimensions = {
    InstanceId = aws_instance.project3_ec2.id
  }

  treat_missing_data = "notBreaching"
}
