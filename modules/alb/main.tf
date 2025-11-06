resource "aws_lb" "this" {
  name = var.name
  internal = var.internal
  load_balancer_type = "application"
  subnets = var.subnets
  security_groups = []
  enable_deletion_protection = false
  tags = { Name = var.name }
}

resource "aws_lb_target_group" "tg" {
  name = "${var.name}-tg"
  port = var.target_port
  protocol = "HTTP"
  vpc_id = element(var.subnets,0) != "" ? data.aws_subnet.first.vpc_id : ""
  health_check {
    path = "/"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "tga" {
  for_each = toset(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = each.value
  port = var.target_port
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

data "aws_subnet" "first" {
  id = element(var.subnets, 0)
}

