output "ecr_repository" {
  value = aws_ecr_repository.ecr_repo
}

output "ecs_data" {
  value = {
    cluster      = aws_ecs_cluster.ecs_cluster.name
    dev_service  = aws_ecs_service.service_dev.name
    prod_service = aws_ecs_service.service_prod.name
  }
}

output "dev_task_definition" {
  value = {
    name               = replace(var.dev_ecs_task.name, "%appname%", var.app_name)
    role               = aws_iam_role.ecs_task_execution_role.arn
    container_name     = var.dev_ecs_task.container_name
    memory_reservation = var.dev_ecs_task.memory_reservation
    port               = var.dev_ecs_task.port
    log_group          = replace(var.dev_ecs_task.log_group, "%appname%", var.app_name)
  }
}

output "prod_task_definition" {
  value = {
    name               = replace(var.prod_ecs_task.name, "%appname%", var.app_name)
    role               = aws_iam_role.ecs_task_execution_role.arn
    container_name     = var.prod_ecs_task.container_name
    memory_reservation = var.prod_ecs_task.memory_reservation
    port               = var.prod_ecs_task.port
    log_group          = replace(var.prod_ecs_task.log_group, "%appname%", var.app_name)
  }
}

output "prod_load_balancer" {
  value = {
    prod_listener = aws_lb_listener.http_prod.arn
    test_listener = aws_lb_listener.test_listener.arn
    targetgroup_1 = aws_lb_target_group.prod_1.name
    targetgroup_2 = aws_lb_target_group.prod_2.name
  }
}

output "load_balancers" {
  value = {
    development = aws_lb.alb_dev.dns_name
    production  = aws_lb.alb_prod.dns_name
  }
}