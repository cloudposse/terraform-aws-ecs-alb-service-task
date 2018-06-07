output "alb_arn" {
  value       = "${aws_lb.test.arn}"
  description = "The arn of the ALB"
}
