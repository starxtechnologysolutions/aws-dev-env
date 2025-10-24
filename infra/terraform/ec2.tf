locals {
  mq_host = regex(
    "^[^:/]+",
    element(
      split("://", aws_mq_broker.rabbit.instances[0].endpoints[0]),
      length(split("://", aws_mq_broker.rabbit.instances[0].endpoints[0])) - 1
    )
  )
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash -xe

    dnf -y update || true
    dnf -y install amazon-ssm-agent ec2-instance-connect || true

    systemctl enable amazon-ssm-agent
    systemctl restart amazon-ssm-agent
    systemctl enable --now ec2-instance-connect
  EOF

  tags = { Name = "${var.project}-${var.env}-ec2", Env = var.env, Project = "Starter", Owner = "Roy" }
}
