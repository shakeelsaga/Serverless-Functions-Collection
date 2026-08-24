# Zips the existing lambda_function.py in place - no manual packaging step
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "${path.module}/build/lambda_function.zip"
}

locals {
  # SLACK_WEBHOOK_URL is only set when a value is actually provided, so the
  # function's own "if not SLACK_URL" silent-mode check behaves the same as
  # it would with the env var left unset entirely.
  env_vars = var.slack_webhook_url != "" ? {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  } : {}
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  description      = "Creates tagged EBS snapshots on a schedule and prunes ones older than the 7-day retention window."
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = local.env_vars
  }

  tags = local.tags

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.lambda,
  ]
}
