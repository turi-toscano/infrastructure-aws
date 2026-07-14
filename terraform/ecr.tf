locals {
    ecr_repositories = [
        "frontend",
        "poll-service",
        "results-service",
    ]
}

resource "aws_ecr_repository" "app" {
    for_each = toset(local.ecr_repositories)
    name = "${var.project}-${each.value}"
    image_tag_mutability = "MUTABLE"
    force_delete = true
    
    image_scanning_configuration {
        scan_on_push = true
    }
    
    tags = {
        Name = "${var.project}-${each.value}"
    }
}

resource "aws_ecr_lifecycle_policy" "app" {
    for_each = aws_ecr_repository.app
    repository = each.value.name
    
    policy = jsonencode({
        rules = [{
            rulePriority = 1
            description  = "Mantieni solo le ultime 10 immagini"
            selection = {
                tagStatus   = "any"
                countType   = "imageCountMoreThan"
                countNumber = 10
            }
            
            action = {
                type = "expire"
            }
        }]
    })
}
