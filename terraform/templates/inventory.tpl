[control_plane]
control-plane ansible_host=${control_plane_private_ip} ansible_ssh_private_key_file=${node_private_key_path}

[bastion]
bastion-1 ansible_host=${bastion_public_ip} ansible_ssh_private_key_file=${bastion_private_key_path}

[all:vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
aws_region=${aws_region}
ssm_join_command_path=${ssm_join_command_path}
ssm_kubeconfig_path=${ssm_kubeconfig_path}
pod_network_cidr=${pod_network_cidr}
ingress_node_port=${ingress_node_port}
expected_workers=${expected_workers}

[bastion:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no

[control_plane:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${bastion_private_key_path} ubuntu@${bastion_public_ip}"