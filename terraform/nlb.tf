resource "aws_lb" "ingress" {
    name = "${var.project}-nlb"
    load_balancer_type = "network"
    internal = false
    subnets = aws_subnet.public[*].id
    security_groups = [aws_security_group.nlb.id]
    enable_cross_zone_load_balancing = true
    tags = {
        Name = "${var.project}-nlb"
    }
}

resource "aws_lb_target_group" "ingress" {
    name = "${var.project}-ingress-tg"
    port = var.ingress_node_port
    protocol = "TCP"
    target_type = "instance"
    vpc_id = aws_vpc.main.id
    preserve_client_ip = "true"
    
    health_check {
        protocol = "TCP"
        port = "traffic-port"
    }
    
    tags = {
        Name = "${var.project}-nlb-tg"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.ingress.arn
    port = 80
    protocol = "TCP"
    
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.ingress.arn
    }
}
