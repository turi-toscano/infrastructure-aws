resource "aws_iam_role" "control_plane" {
    name = "${var.project}-control-plane-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "control_plane_ssm" {
    name = "ssm-policy"
    role = aws_iam_role.control_plane.id
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ssm:PutParameter",
                    "ssm:GetParameter"
                ]
                Resource = "arn:aws:ssm:${var.aws_region}:*:parameter${var.ssm_join_command_path}"
            },
            {
                Effect = "Allow"
                Action = [
                    "kms:Encrypt",
                    "kms:Decrypt",
                    "kms:GenerateDataKey"
                ]
                
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_instance_profile" "control_plane" {
    name = "${var.project}-control-plane-profile"
    role = aws_iam_role.control_plane.name
}

resource "aws_iam_role" "workers" {
    name = "${var.project}-workers-role"
    
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "workers_ssm" {
    name = "ssm-ecr-policy"
    role = aws_iam_role.workers.id
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ssm:GetParameter"
                ]
                Resource = "arn:aws:ssm:${var.aws_region}:*:parameter${var.ssm_join_command_path}"
            },
            {
                Effect = "Allow"
                Action = [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "kms:Decrypt"
                ]
                
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_instance_profile" "workers" {
    name = "${var.project}-workers-profile"
    role = aws_iam_role.workers.name
}

resource "aws_iam_role" "bastion_host" {
    name = "${var.project}-bastion-role"
    
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "bastion_host_ssm" {
    name = "ssm-policy"
    role = aws_iam_role.bastion_host.id
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ssm:GetParameter"
                ]
                Resource = "arn:aws:ssm:${var.aws_region}:*:parameter${var.ssm_kubeconfig_path}"
            },
            {
                Effect = "Allow"
                Action = [
                    "kms:Decrypt"
                ]
                
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_instance_profile" "bastion_host" {
    name = "${var.project}-bastion-profile"
    role = aws_iam_role.bastion_host.name
}