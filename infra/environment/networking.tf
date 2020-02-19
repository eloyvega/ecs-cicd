#--------------------------------------------------------------
# Default VPC and Subnets
#--------------------------------------------------------------

resource "aws_default_vpc" "default_vpc" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_default_subnet" "default_subnets" {
  count             = length(data.aws_availability_zones.available.names)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

#--------------------------------------------------------------
# Security Group for Application Load Balancer
#--------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb"
  description = "Security group for incoming web traffic from internet"
  vpc_id      = aws_default_vpc.default_vpc.id
}

resource "aws_security_group_rule" "allow_internet_traffic" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port        = "80"
  to_port          = "80"
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_test_listener_traffic" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port        = "8080"
  to_port          = "8080"
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_outbound_traffic_alb" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

#--------------------------------------------------------------
# Security Group for EC2 Instances
#--------------------------------------------------------------
resource "aws_security_group" "instance" {
  name        = "${var.app_name}-instance"
  description = "Security group for incoming traffic from load balancer"
  vpc_id      = aws_default_vpc.default_vpc.id
}

resource "aws_security_group_rule" "allow_traffic_from_alb" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port                = "0"
  to_port                  = "65535"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "allow_outbound_traffic_instance" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

#--------------------------------------------------------------
# Application Load Balancer for development
#--------------------------------------------------------------
resource "aws_lb" "alb_dev" {
  name               = "${var.app_name}-dev"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_default_subnet.default_subnets[*].id
}

resource "aws_lb_listener" "http_dev" {
  load_balancer_arn = aws_lb.alb_dev.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_default.arn
  }
}

resource "aws_lb_target_group" "dev_default" {
  name                 = "${var.app_name}-dev"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_default_vpc.default_vpc.id
  deregistration_delay = 60

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 25
    interval            = 30
    matcher             = "200"
  }
}

#--------------------------------------------------------------
# Application Load Balancer for production
#--------------------------------------------------------------
resource "aws_lb" "alb_prod" {
  name               = "${var.app_name}-prod"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_default_subnet.default_subnets[*].id
}

resource "aws_lb_listener" "http_prod" {
  load_balancer_arn = aws_lb.alb_prod.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_1.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.alb_prod.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_2.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_target_group" "prod_1" {
  name                 = "${var.app_name}-prod-1"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_default_vpc.default_vpc.id
  deregistration_delay = 60

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 25
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "prod_2" {
  name                 = "${var.app_name}-prod-2"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_default_vpc.default_vpc.id
  deregistration_delay = 60

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 25
    interval            = 30
    matcher             = "200"
  }
}

