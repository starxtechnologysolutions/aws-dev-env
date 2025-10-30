resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project}-${var.env}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow"
        Principal = { AWS = ["arn:aws:iam::699475954652:user/Watson", "arn:aws:iam::699475954652:user/Ivan", "arn:aws:iam::699475954652:user/Roy"] }
        Action    = "sts:AssumeRole"
      }
    ]
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
    Version : "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Action = ["secretsmanager:GetSecretValue"],
      Resource = [
        aws_secretsmanager_secret.rds_app.arn,
        aws_secretsmanager_secret.rabbit_app.arn
      ]
    }]
  })
}

# S3 permissions for app bucket
resource "aws_iam_role_policy" "ec2_s3_rw" {
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect   = "Allow",
      Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
      Resource = [aws_s3_bucket.app_bucket.arn, "${aws_s3_bucket.app_bucket.arn}/*"]
    }]
  })
}

resource "aws_iam_role_policy" "ec2_ssm_session" {
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowStartSessionToInstances"
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:managed-instance/*",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      {
        Sid    = "AllowSessionDocuments"
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = [
          "arn:aws:ssm:${var.aws_region}::document/AWS-StartSSHSession",
          "arn:aws:ssm:${var.aws_region}::document/AWS-StartPortForwardingSession",
          "arn:aws:ssm:${var.aws_region}::document/AWS-StartPortForwardingSessionToRemoteHost",
          "arn:aws:ssm:${var.aws_region}::document/AWS-StartSession",
          "arn:aws:ssm:${var.aws_region}::document/SSM-SessionManagerRunShell"
        ]
      },
      {
        Sid    = "AllowSessionMetadata"
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:TerminateSession",
          "ssm:ResumeSession"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy" "ec2_ssm_parameter_access" {
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory"
      ],
      Resource = [
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.env}/*",
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/shared/github/pat-readonly"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-${var.env}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}











