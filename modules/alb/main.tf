resource "aws_lb" "this" {
  name = var.name
  internal = var.internal
  load_balancer_type = "application"
  subnets = var.subnets
  security_groups = [aws_security_group.alb_sg.id]
  enable_deletion_protection = false
  tags = { Name = var.name }
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  for_each = {
    for idx, id in var.target_instance_ids : idx => id
  }

  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value
  port             = var.target_port
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

