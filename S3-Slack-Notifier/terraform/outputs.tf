output "function_name" {
  description = "Name of the deployed Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the deployed Lambda function."
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  description = "ARN of the Lambda's execution role."
  value       = aws_iam_role.lambda.arn
}

output "log_group_name" {
  description = "CloudWatch Logs group name."
  value       = aws_cloudwatch_log_group.this.name
}

output "created_new_bucket" {
  description = "Whether this apply created a new bucket (true) or attached to existing buckets only (false)."
  value       = local.create_new_bucket
}

output "registered_buckets" {
  description = "Every bucket currently wired to send upload notifications to this Lambda."
  value       = [for cfg in values(local.bucket_configs) : cfg.id]
}
