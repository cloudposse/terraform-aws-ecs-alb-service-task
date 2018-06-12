module "lb_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.1.2"
  attributes = ["lb"]
  delimiter  = "${var.delimiter}"
  name       = "${var.name}"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  tags       = "${var.tags}"
}

resource "aws_security_group" "default" {
  description = "Controls access to the ALB"

  vpc_id = "${module.vpc.vpc_id}"
  name   = "${module.lb_label.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "default" {
  name               = "${module.lb_label.id}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${module.vpc.vpc_default_security_group_id}", "${aws_security_group.default.id}"]
  subnets            = ["${module.dynamic_subnets.public_subnet_ids}"]
}

resource "aws_lb_target_group" "default" {
  name        = "${module.lb_label.id}"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = "${module.vpc.vpc_id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "default" {
  load_balancer_arn = "${aws_lb.default.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.default.arn}"
    type             = "forward"
  }
}
