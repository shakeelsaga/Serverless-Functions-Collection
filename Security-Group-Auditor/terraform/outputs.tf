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

output "schedule_rule_arn" {
  description = "ARN of the EventBridge rule driving the schedule."
  value       = aws_cloudwatch_event_rule.schedule.arn
}
