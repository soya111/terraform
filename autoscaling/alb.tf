resource "aws_lb_target_group" "nginx" {
  name     = "nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_lb" "nginx" {
  name               = "nginx"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id, data.aws_security_group.default.id]
  subnets            = [data.aws_subnet.ap-northeast-1a.id, data.aws_subnet.ap-northeast-1c.id, data.aws_subnet.ap-northeast-1d.id]
}
