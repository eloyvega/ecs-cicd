#--------------------------------------------------------------
# Launch Configuration
#--------------------------------------------------------------
data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized"]
  }
  owners = ["amazon"]
}

data "template_file" "user_data" {
  template = file("${path.module}/files/user-data.sh")

  vars = {
    cluster_name = var.app_name
  }
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  name_prefix          = var.app_name
  image_id             = data.aws_ami.ecs_optimized_ami.image_id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.instance.id]
  user_data            = data.template_file.user_data.rendered
  key_name             = var.key_name == "" ? null : var.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.arn

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------
# Auto Scaling Group
#--------------------------------------------------------------
resource "aws_autoscaling_group" "ecs_asg" {
  name_prefix          = var.app_name
  launch_configuration = aws_launch_configuration.ecs_launch_configuration.id
  vpc_zone_identifier  = aws_default_subnet.default_subnets[*].id

  min_size         = var.cluster_min_size
  max_size         = var.cluster_max_size
  desired_capacity = var.cluster_size

  tag {
    key                 = "Name"
    value               = "${var.app_name}-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------
# ECR repo
#--------------------------------------------------------------
resource "aws_ecr_repository" "ecr_repo" {
  name = var.app_name
}

#--------------------------------------------------------------
# ECS Cluster
#--------------------------------------------------------------
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.app_name
}

#--------------------------------------------------------------
# ECS Task Definitions
#--------------------------------------------------------------
data "template_file" "container_definition_dev" {
  template = "${file("${path.module}/files/container-definition.json")}"

  vars = {
    container_name     = var.dev_ecs_task.container_name
    image_repository   = aws_ecr_repository.ecr_repo.repository_url
    image_tag          = "latest"
    memory_reservation = var.dev_ecs_task.memory_reservation
    port               = var.dev_ecs_task.port
    log_group          = replace(var.dev_ecs_task.log_group, "%appname%", var.app_name)
    region             = var.region
  }
}

data "template_file" "container_definition_prod" {
  template = file("${path.module}/files/container-definition.json")

  vars = {
    container_name     = var.prod_ecs_task.container_name
    image_repository   = aws_ecr_repository.ecr_repo.repository_url
    image_tag          = "latest"
    memory_reservation = var.prod_ecs_task.memory_reservation
    port               = var.prod_ecs_task.port
    log_group          = replace(var.prod_ecs_task.log_group, "%appname%", var.app_name)
    region             = var.region
  }
}

resource "aws_ecs_task_definition" "task_dev" {
  family                   = replace(var.dev_ecs_task.name, "%appname%", var.app_name)
  container_definitions    = data.template_file.container_definition_dev.rendered
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_task_definition" "task_prod" {
  family                   = replace(var.prod_ecs_task.name, "%appname%", var.app_name)
  container_definitions    = data.template_file.container_definition_prod.rendered
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["EC2"]
}

resource "aws_cloudwatch_log_group" "logs_dev" {
  name = replace(var.dev_ecs_task.log_group, "%appname%", var.app_name)
}

resource "aws_cloudwatch_log_group" "logs_prod" {
  name = replace(var.prod_ecs_task.log_group, "%appname%", var.app_name)
}

#--------------------------------------------------------------
# ECS Services
#--------------------------------------------------------------
resource "aws_ecs_service" "service_dev" {
  name            = "development"
  cluster         = aws_ecs_cluster.ecs_cluster.name
  task_definition = aws_ecs_task_definition.task_dev.arn
  desired_count   = 1
  iam_role        = data.aws_iam_role.AWSServiceRoleForECS.arn
  depends_on      = [aws_lb_listener.http_dev, aws_cloudwatch_log_group.logs_dev]

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dev_default.arn
    container_name   = var.dev_ecs_task.container_name
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

resource "aws_ecs_service" "service_prod" {
  name            = "production"
  cluster         = aws_ecs_cluster.ecs_cluster.name
  task_definition = aws_ecs_task_definition.task_prod.arn
  desired_count   = 1
  iam_role        = data.aws_iam_role.AWSServiceRoleForECS.arn
  depends_on      = [aws_lb_listener.http_prod, aws_cloudwatch_log_group.logs_prod]

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prod_1.arn
    container_name   = var.prod_ecs_task.container_name
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer]
  }
}