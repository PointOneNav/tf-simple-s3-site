output "deployer" {
  description = "IAM access key and secret for CI/CD deployments to the S3 bucket"
  value = var.create_iam_user ? {
    access_key = aws_iam_access_key.deployer[0].id
    secret     = aws_iam_access_key.deployer[0].secret
  } : null
  sensitive = true
}

output "github_actions_role" {
  description = "IAM role ARN for GitHub Actions OIDC deployments"
  value       = var.github_actions_deploy != null ? aws_iam_role.github_actions[0].arn : null
}
