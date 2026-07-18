resource "aws_lb" "ingress" {
    name = "${var.project}-alb"
    load_balancer_type = "network"
    internal = false
    subnets = aws_subnet.public[*].id
    security_groups = [aws_security_group.nlb.id]
    enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "ingress" {
    name = "${var.project}-ingress-tg"
    port = var.ingress_node_port
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = aws_vpc.main.id
    
    health_check {
        protocol = "HTTP"
        path = "/healthz"
        port = "traffic-port"
        matcher = "200"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.ingress.arn
    port = 80
    protocol = "HTTP"
    
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.ingress.arn
    }
}
