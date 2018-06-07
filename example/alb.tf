resource "aws_security_group" "lb_sg" {
  description = "controls access to the ALB"

  vpc_id = "${module.vpc.vpc_id}"
  name   = "tf-ecs-lbsg"

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

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_lb" "default" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${module.vpc.vpc_default_security_group_id}", "${aws_security_group.lb_sg.id}"]
  subnets            = ["${module.dynamic_subnets.public_subnet_ids}"]
}
