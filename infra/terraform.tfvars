region              = "us-east-1"
app_name            = "ecs-cicd"
instance_type       = "t2.micro"
key_name            = ""
cluster_min_size    = 1
cluster_max_size    = 1
cluster_size        = 1
deployment_strategy = "CodeDeployDefault.ECSAllAtOnce"
# You can try:
# CodeDeployDefault.ECSAllAtOnce
# CodeDeployDefault.ECSLinear10PercentEvery1Minutes
# CodeDeployDefault.ECSLinear10PercentEvery3Minutes
# CodeDeployDefault.ECSCanary10Percent5Minutes
# CodeDeployDefault.ECSCanary10Percent15Minutes

dev_ecs_task = {
  name               = "%appname%-dev"
  container_name     = "app"
  memory_reservation = 32
  log_group          = "/ecs/%appname%/dev/app"
  port               = 80
}
prod_ecs_task = {
  name               = "%appname%-prod"
  container_name     = "app"
  memory_reservation = 64
  log_group          = "/ecs/%appname%/prod/app"
  port               = 80
}