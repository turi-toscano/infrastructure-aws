data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"] # Canonical
    
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-*"]
    }
}

resource "aws_key_pair" "bastion" {
    key_name = "${var.project}-bastion-key"
    public_key = var.bastion_public_key
}

resource "aws_key_pair" "node" {
    key_name = "${var.project}-node-key"
    public_key = var.node_public_key
}

resource "aws_instance" "bastion" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.bastion_instance_type
    key_name = aws_key_pair.bastion.key_name
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_security_group.bastion.id]
    iam_instance_profile = aws_iam_instance_profile.bastion_host.name
    associate_public_ip_address = true

    tags = {
        Name = "${var.project}-bastion"
        Role = "bastion"
    }
}

resource "aws_instance" "control_plane" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.control_plane_instance_type
    key_name = aws_key_pair.node.key_name
    subnet_id = aws_subnet.private[0].id
    vpc_security_group_ids = [aws_security_group.node.id]
    iam_instance_profile = aws_iam_instance_profile.control_plane.name
    user_data = base64encode(templatefile("${path.module}/templates/node-user-data.sh.tpl", {
        k8s_minor_version = var.k8s_minor_version
        enable_join = false
        aws_region = var.aws_region
        ssm_join_command_path = var.ssm_join_command_path
    }))
    depends_on = [aws_nat_gateway.nat]

    tags = {
        Name = "${var.project}-control-plane"
        Role = "control-plane"
    }
}

resource "aws_launch_template" "worker" {
    name_prefix = "${var.project}-worker"
    image_id = data.aws_ami.ubuntu.id
    instance_type = var.worker_instance_type
    key_name = aws_key_pair.node.key_name
    user_data = base64encode(templatefile("${path.module}/templates/node-user-data.sh.tpl", {
        k8s_minor_version = var.k8s_minor_version
        enable_join = true
        aws_region = var.aws_region
        ssm_join_command_path = var.ssm_join_command_path
    }))
    
    iam_instance_profile {
        name = aws_iam_instance_profile.workers.name
    }
    
    vpc_security_group_ids = [aws_security_group.node.id]
    
    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "${var.project}-worker"
            Role = "worker"
        }
    }
}

resource "aws_autoscaling_group" "worker" {
    name = "${var.project}-worker-asg"
    vpc_zone_identifier = aws_subnet.private[*].id
    min_size = var.worker_min_size
    desired_capacity = var.worker_desired_capacity
    max_size = var.worker_max_size
    target_group_arns = [aws_lb_target_group.ingress.arn]
    health_check_type = "EC2"
    health_check_grace_period = 300
    wait_for_capacity_timeout = "0"
    
    launch_template {
        id = aws_launch_template.worker.id
        version = "$Latest"
    }
    
    depends_on = [aws_nat_gateway.nat]
}

resource "aws_autoscaling_policy" "worker_cpu" {
    name = "${var.project}-worker-cpu-target"
    autoscaling_group_name = aws_autoscaling_group.worker.name
    policy_type = "TargetTrackingScaling"
    
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        
        target_value = var.worker_cpu_target
    }
}
