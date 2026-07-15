resource "aws_security_group" "nlb" {
    name = "${var.project}-nlb-sg"
    vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "nlb_http" {
    security_group_id = aws_security_group.nlb.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "nlb_to_nodeport" {
    security_group_id = aws_security_group.nlb.id
    referenced_security_group_id = aws_security_group.node.id
    from_port = var.ingress_node_port
    to_port = var.ingress_node_port
    ip_protocol = "tcp"
}

resource "aws_security_group" "bastion" {
    name = "${var.project}-bastion-sg"
    vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
    security_group_id = aws_security_group.bastion.id
    cidr_ipv4 = var.ssh_allowed_cidr
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
    security_group_id = aws_security_group.bastion.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

resource "aws_security_group" "node" {
    name = "${var.project}-node-sg"
    vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "node_nodeport_from_nlb" {
    security_group_id = aws_security_group.node.id
    referenced_security_group_id = aws_security_group.nlb.id
    from_port = var.ingress_node_port
    to_port = var.ingress_node_port
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "node_ssh_from_bastion" {
    security_group_id = aws_security_group.node.id
    referenced_security_group_id = aws_security_group.bastion.id
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "node_api_from_bastion" {
    security_group_id = aws_security_group.node.id
    referenced_security_group_id = aws_security_group.bastion.id
    from_port = 6443
    to_port = 6443
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "node_self" {
    security_group_id = aws_security_group.node.id
    description = "Tutto il traffico tra i nodi del cluster"
    referenced_security_group_id = aws_security_group.node.id
    ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
    security_group_id = aws_security_group.node.id
    description = "Uscita libera via NAT"
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

resource "aws_security_group" "docdb" {
    name = "${var.project}-docdb-sg"
    vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "docdb_from_nodes" {
    security_group_id = aws_security_group.docdb.id
    referenced_security_group_id = aws_security_group.node.id
    from_port = 27017
    to_port = 27017
    ip_protocol = "tcp"
}