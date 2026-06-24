locals {
  cloudfront_id = var.bucket
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

#trivy:ignore:AWS-0011: WAF skipped to minimize cost
resource "aws_cloudfront_distribution" "export" {
  # checkov:skip=CKV_AWS_86: Access logging skipped to minimize cost
  # checkov:skip=CKV_AWS_68: WAF skipped to minimize cost
  # checkov:skip=CKV2_AWS_47: WAF with Log4j AMR skipped to minimize cost
  # checkov:skip=CKV_AWS_310: Origin failover unnecessary for single-origin static site
  # checkov:skip=CKV_AWS_374: Geo restriction intentionally disabled
  origin {
    domain_name              = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.cloudfront_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.bucket} static site serving"
  default_root_object = "index.html"

  aliases = var.hostnames

  dynamic "custom_error_response" {
    for_each = var.redirect_404_spa ? [403, 404] : []
    content {
      error_code            = custom_error_response.value
      error_caching_min_ttl = 1
      response_code         = 200
      response_page_path    = "/index.html"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.cloudfront_id

    compress = true

    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }
  }

  price_class = "PriceClass_100"

  tags = merge(var.tags, { Name = var.bucket })

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.hosting.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  wait_for_deployment = false
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${var.bucket}-default"
  description                       = "Default policy for accessing S3 for contents of ${var.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "redirect" {
  name    = "${var.bucket}-redirect"
  runtime = "cloudfront-js-2.0"
  publish = true
  comment = "Redirects when ending in a slash"
  code    = file("${path.module}/redirect.js")
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.bucket}-security-headers"
  comment = "Security headers for ${var.bucket}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}
