resource "aws_s3_bucket" "storage" {
  # checkov:skip=CKV2_AWS_61: Lifecycle not needed for public static content
  # checkov:skip=CKV2_AWS_62: Event notifications not applicable to static site
  # checkov:skip=CKV_AWS_18: Access logging skipped to minimize cost
  # checkov:skip=CKV_AWS_21: Versioning disabled to avoid serving stale content
  # checkov:skip=CKV_AWS_144: Cross-region replication not needed for single-region static site
  # checkov:skip=CKV_AWS_145: SSE-S3 sufficient; KMS adds cost for static content
  bucket = var.bucket
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Disabled"
  }
}

# checkov:skip=CKV_AWS_145: SSE-S3 sufficient; KMS adds cost for static content
#trivy:ignore:AWS-0132: SSE-S3 sufficient; KMS adds cost
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket                  = aws_s3_bucket.storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "storage" {
  bucket = aws_s3_bucket.storage.bucket

  error_document {
    key = "index.html"
  }
  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "storage_cloudfront_access" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.storage.arn, "${aws_s3_bucket.storage.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.export.arn]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

resource "aws_s3_bucket_policy" "storage_cloudfront_access" {
  bucket = aws_s3_bucket.storage.bucket
  policy = data.aws_iam_policy_document.storage_cloudfront_access.json
}
