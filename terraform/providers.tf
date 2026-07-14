terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    
    backend "s3" {
        bucket = "turi-easy-polls-tofu-state"
        key = "easy-polls/terraform.tfstate"
        region = "eu-central-1"
        dynamodb_table = "tofu-state-lock"
        encrypt = true
    }
}

provider "aws" {
    region = var.aws_region
}