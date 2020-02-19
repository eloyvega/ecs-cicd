resource "aws_codedeploy_app" "deploy" {
  compute_platform = "ECS"
  name             = var.app_name
}

resource "aws_codedeploy_deployment_group" "prod" {
  deployment_group_name  = "production"
  app_name               = aws_codedeploy_app.deploy.name
  deployment_config_name = var.deployment_strategy
  service_role_arn       = aws_iam_role.deploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 10
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_data.cluster
    service_name = var.ecs_data.prod_service
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_load_balancer.prod_listener]
      }

      test_traffic_route {
        listener_arns = [var.prod_load_balancer.test_listener]
      }

      target_group {
        name = var.prod_load_balancer.targetgroup_1
      }

      target_group {
        name = var.prod_load_balancer.targetgroup_2
      }
    }
  }
}