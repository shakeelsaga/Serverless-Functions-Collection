variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to prefix created resources."
  type        = string
  default     = "security-group-auditor"
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
  description = "Lambda timeout in seconds. Set high enough to walk every security group in the account/region."
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
  description = "EventBridge schedule expression for how often the audit runs. Default: every 15 minutes, reflecting the 'continuous compliance guardrail' role described for this function."
  type        = string
  default     = "rate(15 minutes)"
}

variable "slack_webhook_url" {
  description = "Optional Slack incoming webhook URL. Leave blank to run in silent mode (no SLACK_WEBHOOK_URL env var is set)."
  type        = string
  default     = ""
  sensitive   = true
}
