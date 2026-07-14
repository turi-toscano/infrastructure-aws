variable "project" {
    description = "Prefisso usato per il naming e i tag delle risorse"
    type = string
    default = "easy-polls"
}

variable "aws_region" {
    type = string
    default = "eu-central-1"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
    type = list(string)
    default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
    type = list(string)
    default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "pod_network_cidr" {
    type = string
    default = "10.244.0.0/16"
}

variable "ssh_allowed_cidr" {
    type = string
    default = "0.0.0.0/0"
}

variable "control_plane_instance_type" {
    description = "Sono necessarie almeno 2 CPU per far funzionare kubeadm"
    type = string
    default = "t3.medium"
}

variable "worker_instance_type" {
    description = "Sono necessari almeno 2 GB di RAM per far funzionare kubeadm"
    type = string
    default = "t3.small"
}

variable "bastion_instance_type" {
    type = string
    default = "t3.micro"
}

variable "worker_min_size" {
    description = "Numero minimo di worker nell'Auto Scaling Group"
    type = number
    default = 2
}

variable "worker_desired_capacity" {
    description = "Numero desiderato di worker"
    type = number
    default = 2
}

variable "worker_max_size" {
    description = "Numero massimo di worker nell'Auto Scaling Group"
    type = number
    default = 4
}

variable "worker_cpu_target" {
    description = "Utilizzo CPU medio a cui punta la target-tracking policy dell'ASG"
    type = number
    default = 18
}

variable "node_root_volume_size" {
    description = "Dimensione (GiB) del volume root dei nodi"
    type = number
    default = 20
}

variable "k8s_minor_version" {
    type = string
    default = "v1.31"
}

variable "ingress_node_port" {
    description = "NodePort su cui ascolta ingress-nginx"
    type = number
    default = 30080
}

variable "docdb_instance_class" {
    type = string
    default = "db.t3.medium"
}

variable "docdb_engine_version" {
    type = string
    default = "5.0.0"
}

variable "docdb_master_username" {
    type = string
    default = "easypolls"
}

variable "docdb_master_password" {
    type = string
    sensitive = true
}

variable "docdb_tls" {
    type = string
    default = "disabled"
}

variable "ssm_join_command_path" {
    description = "Path SSM dove il control plane pubblica il join command"
    type = string
    default = "/easy-polls/join-command"
}

variable "ssm_kubeconfig_path" {
    description = "Path SSM dove viene pubblicato il kubeconfig. Il bastion lo legge per usare kubectl"
    type = string
    default = "/easy-polls/kubeconfig"
}

variable "bastion_public_key" {
    type = string
    sensitive = true
}

variable "node_public_key" {
    type = string
    sensitive = true
}

variable "bastion_private_key_path" {
    type = string
    default = "bastion_key"
}

variable "node_private_key_path" {
    type = string
    default = "node_key"
}

variable "tf_output_dir" {
    type = string
    default = "tf_output"
}
