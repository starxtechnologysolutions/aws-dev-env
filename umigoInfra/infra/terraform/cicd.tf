resource "aws_cloudwatch_log_group" "codebuild_backend" {
  name              = "/aws/codebuild/${var.project}-${var.env}-backend"
  retention_in_days = 30
  tags              = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_codebuild_project" "backend" {
  name          = "${var.project}-${var.env}-backend"
  description   = "Builds and packages the ${var.project} backend"
  service_role  = aws_iam_role.codebuild_service_role.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_backend.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "umigoCrmBackend/buildspec.yml"
  }

  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_codedeploy_app" "backend" {
  name             = "${var.project}-${var.env}-backend"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "backend" {
  app_name               = aws_codedeploy_app.backend.name
  deployment_group_name  = "${var.project}-${var.env}-backend"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Env"
      type  = "KEY_AND_VALUE"
      value = var.env
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "${var.project}-${var.env}-deploy-failure"
    trigger_target_arn = aws_sns_topic.deployment_alerts.arn
  }

  depends_on = [aws_instance.app]
}

resource "aws_sns_topic" "deployment_alerts" {
  name = "${var.project}-${var.env}-deployment-alerts"
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_codepipeline" "backend" {
  name     = "${var.project}-${var.env}-backend"
  role_arn = aws_iam_role.codepipeline_service_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        DetectChanges        = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildArtifact"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.backend.name
        DeploymentGroupName = aws_codedeploy_deployment_group.backend.deployment_group_name
      }
    }
  }

  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

