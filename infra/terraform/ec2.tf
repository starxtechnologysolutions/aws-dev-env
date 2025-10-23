data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter { name = "name" values = ["al2023-ami-*-x86_64"] }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    dnf -y update
    dnf -y install amazon-ssm-agent git docker java-17-openjdk maven
    systemctl enable --now amazon-ssm-agent
    usermod -aG docker ec2-user
  EOF
  tags = { Name = "${var.project}-${var.env}-ec2", Env = var.env, Project = "Starter", Owner = "Roy" }
}

output "ec2_instance_id" { value = aws_instance.app.id }
output "ec2_public_ip"  { value = aws_instance.app.public_ip }
