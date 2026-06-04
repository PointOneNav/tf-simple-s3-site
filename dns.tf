data "aws_route53_zone" "hosted" {
  count        = var.manage_route53_records ? 1 : 0
  name         = var.manage_route53_records ? var.hosted_zone : ""
  private_zone = false

  lifecycle {
    precondition {
      condition     = var.manage_route53_records ? var.hosted_zone != null : true
      error_message = "hosted_zone must be set when manage_route53_records is true."
    }
  }
}

locals {
  validation_records = {
    for dvo in aws_acm_certificate.hosting.domain_validation_options :
    dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = try(data.aws_route53_zone.hosted[0].zone_id, null)
    }
    if var.manage_route53_records
  }
}

resource "aws_route53_record" "validation" {
  for_each = { for k, v in local.validation_records : k => v if var.manage_route53_records }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_route53_record" "host_a" {
  for_each = { for h in toset(var.hostnames) : h => h if var.manage_route53_records }

  name            = each.value
  type            = "A"
  zone_id         = data.aws_route53_zone.hosted[0].zone_id
  allow_overwrite = true

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.export.domain_name
    zone_id                = aws_cloudfront_distribution.export.hosted_zone_id
  }
}

resource "aws_route53_record" "host_aaaa" {
  for_each = { for h in toset(var.hostnames) : h => h if var.manage_route53_records }

  name            = each.value
  type            = "AAAA"
  zone_id         = data.aws_route53_zone.hosted[0].zone_id
  allow_overwrite = true

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.export.domain_name
    zone_id                = aws_cloudfront_distribution.export.hosted_zone_id
  }
}
