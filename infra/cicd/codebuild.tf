#--------------------------------------------------------------
# CodeBuild Project
#--------------------------------------------------------------
resource "aws_codebuild_project" "build" {
  name         = "${var.app_name}-build"
  service_role = aws_iam_role.build_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "REGION"
      value = var.region
    }

    environment_variable {
      name  = "ECR_URI"
      value = var.ecr_repository.repository_url
    }

    environment_variable {
      name  = "DEV_CONTAINER"
      value = var.dev_task_definition.container_name
    }

    environment_variable {
      name  = "PROD_ROLE_ARN"
      value = var.prod_task_definition.role
    }

    environment_variable {
      name  = "PROD_TASK_FAMILY"
      value = var.prod_task_definition.name
    }

    environment_variable {
      name  = "PROD_CONTAINER"
      value = var.prod_task_definition.container_name
    }

    environment_variable {
      name  = "PROD_MEMORY_RESERVATION"
      value = var.prod_task_definition.memory_reservation
    }

    environment_variable {
      name  = "PROD_PORT"
      value = var.prod_task_definition.port
    }

    environment_variable {
      name  = "PROD_LOG_GROUP"
      value = var.prod_task_definition.log_group
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}