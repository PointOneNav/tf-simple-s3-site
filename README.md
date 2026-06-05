# Simple S3 Site
Terraform module to deploy a simple static site via S3 and fronted with CloudFront.  Theoretically this will result in
$0.00 charges for delivery.  Storage will become your dominate segment.

## Features
* Private S3 storage bucket
* HTTPS certificate for your domain issued via Amazon's free ACM.
* AWS IAM role to deploy to the bucket.
* `index.html` [rewriting for URLs ending with a `/`](redirect.js), allowing for compatability with standard web
development practices.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.42.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.45.0 |
| <a name="provider_aws.us_east_1"></a> [aws.us\_east\_1](#provider\_aws.us\_east\_1) | 6.45.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket"></a> [bucket](#input\_bucket) | Name of the S3 bucket used for static site hosting | `string` | n/a | yes |
| <a name="input_create_iam_user"></a> [create\_iam\_user](#input\_create\_iam\_user) | Whether to create an IAM user with a static access key for CI/CD deployments | `bool` | `true` | no |
| <a name="input_github_actions_deploy"></a> [github\_actions\_deploy](#input\_github\_actions\_deploy) | When set, creates an IAM role assumable by GitHub Actions via OIDC federation.<br/><br/>Format for allowed\_repos: "org/repo", e.g. ["my-org/my-site"].<br/>Format for allowed\_branches: "refs/heads/<pattern>", supports wildcards, e.g. ["refs/heads/main", "refs/heads/release/*"].<br/>Format for allowed\_environments: plain GitHub environment names, e.g. ["production"].<br/><br/>When neither allowed\_branches nor allowed\_environments is set, the trust is open<br/>to all refs and environments within the configured repos. | <pre>object({<br/>    allowed_repos        = list(string)<br/>    allowed_branches     = optional(list(string))<br/>    allowed_environments = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_hosted_zone"></a> [hosted\_zone](#input\_hosted\_zone) | Route53 hosted zone name for DNS records and certificate validation. Required when manage\_route53\_records is true. | `string` | `null` | no |
| <a name="input_hostnames"></a> [hostnames](#input\_hostnames) | DNS hostnames for the CloudFront distribution. The first entry is used as the primary ACM certificate domain; additional entries become Subject Alternative Names | `list(string)` | n/a | yes |
| <a name="input_manage_route53_records"></a> [manage\_route53\_records](#input\_manage\_route53\_records) | When false, skip Route53 zone lookup, DNS validation records, and A/AAAA alias records. Manage DNS and certificate validation externally using the cloudfront and acm\_certificate outputs. | `bool` | `true` | no |
| <a name="input_redirect_404_spa"></a> [redirect\_404\_spa](#input\_redirect\_404\_spa) | When true, 403 and 404 errors return 200 with /index.html to support SPA client-side routing | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_acm_certificate"></a> [acm\_certificate](#output\_acm\_certificate) | ACM certificate details including DNS validation options — use when managing DNS externally |
| <a name="output_cloudfront"></a> [cloudfront](#output\_cloudfront) | CloudFront distribution domain name, hosted zone ID, ID, and ARN |
| <a name="output_deployer"></a> [deployer](#output\_deployer) | IAM access key and secret for CI/CD deployments to the S3 bucket |
| <a name="output_github_actions_role"></a> [github\_actions\_role](#output\_github\_actions\_role) | IAM role ARN for GitHub Actions OIDC deployments |
<!-- END_TF_DOCS -->

> **Note**: You'll need to configure an AWS provider to specifically run in `us-east-1` for the certificate (required by [CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html)). Hosted zone must exist in Route 53.

# Example
```terraform
module "spa" {
  source = "git::https://github.com/meschbach/tf-simple-s3-site.git?ref=v0.0.1"
  bucket = "website-com-example"
  hostnames = ["example.com"]
  hosted_zone = "example.com"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
}

resource "aws_route53_zone" "com_example" {
  name = "example.com"
  comment = "Example website"
}
```

# Philosophy
(steps up on my soapbox and clears throat)

This module aims to provide a simple interface to providing the minimal viable target.  There are a number of great
modules with a ton of tuning knobs which are very hard to understand.  This aims to be simple straight forward
module to accomplish just serving a static website.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, linting, and CI details.
