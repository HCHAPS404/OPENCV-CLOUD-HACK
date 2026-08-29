data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-rabbitmq-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project_name}-rabbitmq-instance-profile"
  role = aws_iam_role.ec2_ssm.name
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf install -y docker
    systemctl enable --now docker
    docker run -d --name rabbitmq \
      --restart unless-stopped \
      -p 5672:5672 -p 15672:15672 \
      -e RABBITMQ_DEFAULT_USER=${var.rabbitmq_user} \
      -e RABBITMQ_DEFAULT_PASS=${var.rabbitmq_password} \
      -v /var/lib/rabbitmq-data:/var/lib/rabbitmq \
      rabbitmq:3.13-management
  EOF
}

resource "aws_instance" "rabbitmq" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  user_data              = local.user_data

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-rabbitmq" }
}
