data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "site" {
  source = "../.."

  bucket    = var.bucket
  hostnames = var.hostnames
  tags      = var.tags

  create_iam_user       = var.create_iam_user
  github_actions_deploy = var.github_actions_deploy

  manage_route53_records = false

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
