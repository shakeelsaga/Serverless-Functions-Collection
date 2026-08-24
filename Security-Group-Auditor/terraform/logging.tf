# Created explicitly (and ahead of the function) so the Lambda's IAM role
# only needs logs:CreateLogStream / logs:PutLogEvents on this one log group,
# rather than the broader logs:CreateLogGroup on Resource "*" that the
# AWSLambdaBasicExecutionRole managed policy would require.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}
