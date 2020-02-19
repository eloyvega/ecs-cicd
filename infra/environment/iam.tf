#--------------------------------------------------------------
# IAM Role and Instance Profile for EC2 instances
#--------------------------------------------------------------
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.app_name}-ecsInstanceRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

data "aws_iam_policy" "AmazonEC2ContainerServiceforEC2Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "sto-readonly-role-policy-attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerServiceforEC2Role.arn
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.app_name}-ecsInstanceRole"
  role = aws_iam_role.ecs_instance_role.name
}

#--------------------------------------------------------------
# ECS Task Execution Role
#--------------------------------------------------------------
data "aws_iam_policy_document" "instance-assume-role-policy-ter" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-ecsTaskExecutionRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy-ter.json
}

data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "taskexecutionrole-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn
}

#--------------------------------------------------------------
# Service Role for ECS
#--------------------------------------------------------------
data "aws_iam_role" "AWSServiceRoleForECS" {
  name = "AWSServiceRoleForECS"
}