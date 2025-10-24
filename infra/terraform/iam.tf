resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project}-${var.env}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow reading dev/* secrets
resource "aws_iam_role_policy" "ec2_read_secrets" {
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: ["secretsmanager:GetSecretValue"],
      Resource: [
        aws_db_instance.postgres.master_user_secret[0].secret_arn,
        aws_secretsmanager_secret.rabbit_app.arn
      ]
    }]
  })
}

# S3 permissions for app bucket
resource "aws_iam_role_policy" "ec2_s3_rw" {
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: ["s3:PutObject","s3:GetObject","s3:ListBucket"],
      Resource: [aws_s3_bucket.app_bucket.arn, "${aws_s3_bucket.app_bucket.arn}/*"]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-${var.env}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}
