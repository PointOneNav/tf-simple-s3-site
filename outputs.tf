output "cloudfront" {
  description = "CloudFront distribution domain name, hosted zone ID, ID, and ARN"
  value = {
    domain_name    = aws_cloudfront_distribution.export.domain_name
    hosted_zone_id = aws_cloudfront_distribution.export.hosted_zone_id
    id             = aws_cloudfront_distribution.export.id
    arn            = aws_cloudfront_distribution.export.arn
  }
}

output "acm_certificate" {
  description = "ACM certificate details including DNS validation options — use when managing DNS externally"
  value = {
    arn                       = aws_acm_certificate.hosting.arn
    domain_name               = aws_acm_certificate.hosting.domain_name
    subject_alternative_names = aws_acm_certificate.hosting.subject_alternative_names
    domain_validation_options = aws_acm_certificate.hosting.domain_validation_options
  }
}

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
