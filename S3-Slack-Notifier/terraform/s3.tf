locals {
  # No existing_bucket_names means: create exactly one new bucket instead.
  create_new_bucket = length(var.existing_bucket_names) == 0
  new_bucket_name    = var.new_bucket_name != "" ? var.new_bucket_name : "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"
}

# Cheap to generate even when unused (existing-bucket mode), so it's left
# ungated rather than count-gated to match create_new_bucket - one less
# conditional to reason about for no real benefit.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ---------------------------------------------------------------------------
# Mode A: create_new_bucket = true -> provision one new bucket with the
# hardening (private, encrypted, versioned) that makes sense for a bucket
# this module owns outright.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "new" {
  count  = local.create_new_bucket ? 1 : 0
  bucket = local.new_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "new" {
  count                   = local.create_new_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.new[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "new" {
  count  = local.create_new_bucket ? 1 : 0
  bucket = aws_s3_bucket.new[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "new" {
  count  = local.create_new_bucket ? 1 : 0
  bucket = aws_s3_bucket.new[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# Mode B: create_new_bucket = false -> look up every bucket the caller
# listed. Read-only lookup; each name must already exist in this account/
# region. Deliberately does NOT touch encryption/versioning/public-access
# settings on these - they're not this module's to manage.
# ---------------------------------------------------------------------------
data "aws_s3_bucket" "existing" {
  for_each = toset(var.existing_bucket_names)
  bucket   = each.value
}

# ---------------------------------------------------------------------------
# Normalizes both modes into one bucket_name => bucket_arn map, so
# everything below (IAM, permissions, notifications) is written once and
# works the same regardless of which mode is active.
# ---------------------------------------------------------------------------
locals {
  bucket_configs = local.create_new_bucket ? {
    "new_bucket" = {
      id  = aws_s3_bucket.new[0].id
      arn = aws_s3_bucket.new[0].arn
    }
    } : {
    for name, b in data.aws_s3_bucket.existing : name => {
      id  = b.id
      arn = b.arn
    }
  }
}

# Registers this Lambda as the S3 event target for every bucket in
# local.bucket_arns - one new bucket, or every bucket the caller listed.
#
# IMPORTANT: aws_s3_bucket_notification owns a bucket's ENTIRE notification
# configuration - the underlying AWS API call is a full replace, not a
# merge. Only register buckets that don't already have some other
# notification (Slack-related or not) configured, or that one is silently
# deleted on apply.
resource "aws_s3_bucket_notification" "this" {
  for_each = local.bucket_configs
  bucket   = each.value.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  for_each       = local.bucket_configs
  statement_id   = "AllowExecutionFromS3-${replace(each.key, ".", "-")}"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.this.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = each.value.arn
  source_account = data.aws_caller_identity.current.account_id
}
