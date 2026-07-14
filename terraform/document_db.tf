resource "aws_docdb_subnet_group" "main" {
    name = "${var.project}-docdb-subnet-group"
    subnet_ids = aws_subnet.private[*].id
    tags = {
        Name = "${var.project}-docdb-subnet-group"
    }
}

resource "aws_docdb_cluster_parameter_group" "main" {
    name = "${var.project}-docdb-params"
    family = "docdb${split(".", var.docdb_engine_version)[0]}.0"

    parameter {
        name = "tls"
        value = var.docdb_tls
    }
}

resource "aws_docdb_cluster" "main" {
    cluster_identifier = "${var.project}-docdb"
    engine = "docdb"
    engine_version = var.docdb_engine_version
    port = 27017

    master_username = var.docdb_master_username
    master_password = var.docdb_master_password

    db_subnet_group_name = aws_docdb_subnet_group.main.name
    db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
    vpc_security_group_ids = [aws_security_group.docdb.id]

    storage_encrypted = true
    backup_retention_period = 1
    skip_final_snapshot = true
    deletion_protection = false
    apply_immediately = true

    tags = {
        Name = "${var.project}-docdb"
    }
}

resource "aws_docdb_cluster_instance" "main" {
    count = 1
    identifier = "${var.project}-docdb-${count.index + 1}"
    cluster_identifier = aws_docdb_cluster.main.id
    instance_class = var.docdb_instance_class
    availability_zone = data.aws_availability_zones.available.names[0]
    apply_immediately = true

    tags = {
        Name = "${var.project}-docdb-${count.index + 1}"
    }
}
