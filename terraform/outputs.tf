resource "local_file" "inventory" {
    filename = "${path.module}/${var.tf_output_dir}/hosts.ini"
    file_permission = "0644"
    
    content = templatefile("${path.module}/templates/inventory.tpl", {
        control_plane_private_ip = aws_instance.control_plane.private_ip
        bastion_public_ip = aws_instance.bastion.public_ip
        node_private_key_path = var.node_private_key_path
        bastion_private_key_path = var.bastion_private_key_path
        aws_region = var.aws_region
        ssm_join_command_path = var.ssm_join_command_path
        ssm_kubeconfig_path = var.ssm_kubeconfig_path
        pod_network_cidr = var.pod_network_cidr
        ingress_node_port = var.ingress_node_port
        expected_workers = var.worker_desired_capacity
    })
}

output "nlb_dns_name" {
    value = aws_lb.ingress.dns_name
}

output "bastion_public_ip" {
    value = aws_instance.bastion.public_ip
}