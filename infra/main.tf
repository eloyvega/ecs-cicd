terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region = var.region
}

module "environment" {
  source = "./environment"

  region           = var.region
  app_name         = var.app_name
  instance_type    = var.instance_type
  key_name         = var.key_name
  cluster_min_size = var.cluster_min_size
  cluster_max_size = var.cluster_max_size
  cluster_size     = var.cluster_size
  dev_ecs_task     = var.dev_ecs_task
  prod_ecs_task    = var.prod_ecs_task
}

output "load_balancers" {
  value = module.environment.load_balancers
}

module "cicd" {
  source = "./cicd"

  region               = var.region
  app_name             = var.app_name
  deployment_strategy  = var.deployment_strategy
  ecr_repository       = module.environment.ecr_repository
  ecs_data             = module.environment.ecs_data
  prod_load_balancer   = module.environment.prod_load_balancer
  dev_task_definition  = module.environment.dev_task_definition
  prod_task_definition = module.environment.prod_task_definition
}

output "repo_url" {
  value = module.cicd.repo_url
}