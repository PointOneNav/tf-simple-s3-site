variable "bucket" {
  type        = string
  description = "Name of the S3 bucket used for static site hosting"
}

variable "hosted_zone" {
  type        = string
  description = "Route53 hosted zone name for DNS records and certificate validation. Required when manage_route53_records is true."
  default     = null
}

variable "manage_route53_records" {
  description = "When false, skip Route53 zone lookup, DNS validation records, and A/AAAA alias records. Manage DNS and certificate validation externally using the cloudfront and acm_certificate outputs."
  type        = bool
  default     = true
}

variable "hostnames" {
  type        = list(string)
  description = "DNS hostnames for the CloudFront distribution. The first entry is used as the primary ACM certificate domain; additional entries become Subject Alternative Names"
  validation {
    condition     = length(var.hostnames) > 0
    error_message = "At least one hostname must be provided."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}

variable "redirect_404_spa" {
  type        = bool
  description = "When true, 403 and 404 errors return 200 with /index.html to support SPA client-side routing"
  default     = false
}

variable "create_iam_user" {
  description = "Whether to create an IAM user with a static access key for CI/CD deployments"
  type        = bool
  default     = true
}

variable "github_actions_deploy" {
  description = <<-EOT
    When set, creates an IAM role assumable by GitHub Actions via OIDC federation.

    Format for allowed_repos: "org/repo", e.g. ["my-org/my-site"].
    Format for allowed_branches: "refs/heads/<pattern>", supports wildcards, e.g. ["refs/heads/main", "refs/heads/release/*"].
    Format for allowed_environments: plain GitHub environment names, e.g. ["production"].

    When neither allowed_branches nor allowed_environments is set, the trust is open
    to all refs and environments within the configured repos.
  EOT
  type = object({
    allowed_repos        = list(string)
    allowed_branches     = optional(list(string))
    allowed_environments = optional(list(string))
  })
  default = null
}
