variable "region" {}
variable "app_name" {}
variable "instance_type" {}
variable "key_name" {}
variable "cluster_min_size" {}
variable "cluster_max_size" {}
variable "cluster_size" {}
variable "dev_ecs_task" {
  default = {
    name               = "%appname%-dev"
    container_name     = "app"
    memory_reservation = 64
    log_group          = "/ecs/%appname%/dev/app"
    port               = 80
  }
}
variable "prod_ecs_task" {
  default = {
    name               = "%appname%-prod"
    container_name     = "app"
    memory_reservation = 64
    log_group          = "/ecs/%appname%/prod/app"
    port               = 80
  }
}