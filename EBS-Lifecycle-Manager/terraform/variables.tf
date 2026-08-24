variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to prefix created resources."
  type        = string
  default     = "ebs-lifecycle-manager"
}

variable "environment" {
  description = "Deployment environment label (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags applied to every resource this module creates."
  type        = map(string)
  default     = {}
}

variable "lambda_runtime" {
  description = "Lambda Python runtime."
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds. Set high enough to iterate every tagged volume/snapshot in the account."
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB."
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period for the function's log group."
  type        = number
  default     = 14
}

variable "schedule_expression" {
  description = "EventBridge schedule expression that triggers the backup/cleanup run. Default: daily at 03:00 UTC."
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "slack_webhook_url" {
  description = "Optional Slack incoming webhook URL. Leave blank to run in silent mode (no SLACK_WEBHOOK_URL env var is set)."
  type        = string
  default     = ""
  sensitive   = true
}
