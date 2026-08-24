data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  # generate_presigned_url() doesn't call AWS itself, but S3 checks the
  # signing principal's permissions at the moment the URL is actually used —
  # so the role needs real GetObject rights on every registered bucket's
  # objects (one new bucket, or every bucket in existing_bucket_names).
  statement {
    sid       = "AllowPresignedGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [for cfg in values(local.bucket_configs) : "${cfg.arn}/*"]
  }

  statement {
    sid       = "AllowLogging"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
