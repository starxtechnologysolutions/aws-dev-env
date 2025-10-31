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
        Effect = "Allow"
        Principal = { AWS = [
          "arn:aws:iam::699475954652:user/Watson",
          "arn:aws:iam::699475954652:user/Ivan",
          "arn:aws:iam::699475954652:user/Roy"
        ] }
        Action = "sts:AssumeRole"
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

# S3 permissions for app and artifact buckets
resource "aws_iam_role_policy" "ec2_s3_rw" {
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Action = ["s3:PutObject", "s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"],
      Resource = [
        aws_s3_bucket.app_bucket.arn,
        "${aws_s3_bucket.app_bucket.arn}/*",
        aws_s3_bucket.artifact_bucket.arn,
        "${aws_s3_bucket.artifact_bucket.arn}/*"
      ]
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

resource "aws_iam_role" "codebuild_service_role" {
  name = "${var.project}-${var.env}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_service_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.codebuild_backend.arn,
          "${aws_cloudwatch_log_group.codebuild_backend.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.artifact_bucket.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${aws_s3_bucket.artifact_bucket.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_service_role" {
  name = "${var.project}-${var.env}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_service_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifact_bucket.arn,
          "${aws_s3_bucket.artifact_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = [aws_codebuild_project.backend.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection"]
        Resource = [var.codestar_connection_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = [
          aws_codedeploy_app.backend.arn,
          aws_codedeploy_deployment_group.backend.arn,
          "arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.codebuild_service_role.arn,
          aws_iam_role.codedeploy_service_role.arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "codebuild.amazonaws.com",
              "codedeploy.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "codedeploy_service_role" {
  name = "${var.project}-${var.env}-codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_iam_role_policy_attachment" "codedeploy_managed" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy" "codedeploy_sns_publish" {
  role = aws_iam_role.codedeploy_service_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sns:Publish"],
      Resource = [aws_sns_topic.deployment_alerts.arn]
    }]
  })
}
